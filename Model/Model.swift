//
//  Model.swift
//  WD Content
//
//  Created by Сергей Сейтов on 23.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

func generateUDID() -> String {
    return UUID().uuidString
}

func releaseDate(_ text:String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    if let date = formatter.date(from: text) {
        let yearFormatter = DateFormatter()
        yearFormatter.dateStyle = .long
        yearFormatter.timeStyle = .none
        return yearFormatter.string(from: date)
    } else {
        return ""
    }
}

func year(_ text:String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    if let date = formatter.date(from: text) {
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        return yearFormatter.string(from: date)
    } else {
        return ""
    }
}

class Model: NSObject {
    
    static let shared = Model()
    
    var userInfo: UserInfo?
    var publicDB: CKDatabase?

    private override init() {
        super.init()
        
        let container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        userInfo = UserInfo(container: container)

    #if TV
        let url = self.applicationDocumentsDirectory.appendingPathComponent("WDContentTV.sqlite")
    #else
        let url = self.applicationDocumentsDirectory.appendingPathComponent("ContentModel.sqlite")
    #endif
        try? FileManager.default.removeItem(at: url)
    }
    
    lazy var applicationDocumentsDirectory: URL = {
#if TV
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
#else
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
#endif
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "WDContent", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("WDContent.sqlite")
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            print("CoreData data error: \(error)")
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                print("Saved data error: \(error)")
            }
        }
    }
    
    @objc func refreshConnections(_ result: @escaping(Error?) -> ()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Connection", predicate: predicate)
        
        publicDB!.perform(query, inZoneWith: nil) { [unowned self] results, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    print("Cloud Query Error - Refresh: \(error)")
                    result(error)
                }
                return
            }
            
            DispatchQueue.main.async {
                for record in results! {
                    self.addConnection(record)
                }
                result(nil)
            }
        }
    }
    
    // MARK: - Connection table
    
    func addConnection(_ record:CKRecord) {
        if let ip = record["ip"] as? String {
            var connection = getConnection(ip)
            if connection == nil {
                connection = NSEntityDescription.insertNewObject(forEntityName: "Connection", into: managedObjectContext) as? Connection
                connection!.ip = ip
                if let port = record["port"] as? String, let portNum = Int(port), let user = record["user"] as? String, let password = record["password"] as? String {
                    
                    connection!.recordName = record.recordID.recordName
                    connection!.zoneName = record.recordID.zoneID.zoneName
                    connection!.ownerName = record.recordID.zoneID.ownerName
                    connection!.port = Int32(portNum)
                    connection!.user = user
                    connection!.password = password
                    saveContext()
                }
            }
        }
    }

    func createConnection(ip:String, port:Int32, user:String, password:String, result: @escaping(Connection?) -> ()) {
        
        if let connection = getConnection(ip) {
            result(connection)
        }
        
        let record = CKRecord(recordType: "Connection")
        record.setValue(ip, forKey: "ip")
        record.setValue("\(port)", forKey: "port")
        record.setValue(user, forKey: "user")
        record.setValue(password, forKey: "password")
        
        publicDB!.save(record, completionHandler: { cloudRecord, error in
            DispatchQueue.main.async {
                if error != nil {
                    result(nil)
                } else {
                    let connection = NSEntityDescription.insertNewObject(forEntityName: "Connection", into: self.managedObjectContext) as! Connection
                    connection.recordName = cloudRecord!.recordID.recordName
                    connection.zoneName = cloudRecord!.recordID.zoneID.zoneName
                    connection.ownerName = cloudRecord!.recordID.zoneID.ownerName
                    connection.ip = ip
                    connection.port = port
                    connection.user = user
                    connection.password = password
                    self.saveContext()
                    result(connection)
                }
            }
        })
    }

    func getConnection(_ address:String) -> Connection? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Connection")
        fetchRequest.predicate = NSPredicate(format: "ip == %@", address)
        if let connection = try? managedObjectContext.fetch(fetchRequest).first as? Connection {
            return connection
        } else {
            return nil
        }
    }
    
    // MARK: - Node table
    
    func addNode(_ file:SMBFile, parent:Node?, connection:Connection? = nil) -> Node {
        let node = NSEntityDescription.insertNewObject(forEntityName: "Node", into: managedObjectContext) as! Node
        node.uid = generateUDID()
        if file.directory {
            node.name = file.name
        } else {
            node.name = (file.name as NSString).deletingPathExtension
        }
        node.path = file.filePath
        node.isFile = !file.directory
        if parent != nil {
            node.parent = parent
            parent?.addToChilds(node)
            node.connection = parent!.connection
            parent!.connection?.addToNodes(node)
        } else {
            node.parent = nil
            node.connection = connection
            connection?.addToNodes(node)
        }
        saveContext()
        return node
    }
    
    func nodes(byRoot:Node?) -> [Node] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Node")
        if byRoot != nil {
            fetchRequest.predicate = NSPredicate(format: "parent.uid == %@", byRoot!.uid!)
        } else {
            fetchRequest.predicate = NSPredicate(format: "parent == NULL")
        }
        let descr1 = NSSortDescriptor(key: "isFile", ascending: true)
        let descr2 = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [descr1, descr2]
        
        if var nodes = try? managedObjectContext.fetch(fetchRequest) as! [Node] {
            if nodes.count == 0 && byRoot != nil {
                let connection = SMBConnection()
                if connection.connect(to: byRoot!.connection!.ip!,
                                      port: byRoot!.connection!.port,
                                      user: byRoot!.connection!.user!,
                                      password: byRoot!.connection!.password!) {
                    let content = connection.folderContents(at: byRoot!.path!) as! [SMBFile]
                    for file in content {
                        let node = addNode(file, parent: byRoot)
                        nodes.append(node)
                    }
                }
            }
            return nodes.sorted(by: { node1, node2 in
                if node1.isFile && node2.isFile {
                    return node1.name! < node2.name!
                } else if !node1.isFile && !node2.isFile {
                    return node1.name! < node2.name!
                } else if node1.isFile {
                    return false
                } else {
                    return true
                }
            })
        } else {
            return []
        }
    }
    
    func node(byPath:String) -> Node? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Node")
        fetchRequest.predicate = NSPredicate(format: "path == %@", byPath)
        if let node = try? managedObjectContext.fetch(fetchRequest).first as? Node {
            return node
        } else {
            return nil
        }
    }
    
    func deleteNode(_ node:Node) {
        node.connection?.removeFromNodes(node)
        if let childs = node.childs?.allObjects as? [Node] {
            for child in childs {
                deleteNode(child)
            }
        }
        clearInfoForNode(node)
        managedObjectContext.delete(node)
        saveContext()
    }
    
    // MARK: - MetaInfo table
    
    func getInfo(_ path:String) -> MetaInfo? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MetaInfo")
        fetchRequest.predicate = NSPredicate(format: "path == %@", path)
        if let info = try? managedObjectContext.fetch(fetchRequest).first as? MetaInfo {
            return info
        } else {
            return nil
        }
    }

    func setInfoForNode(_ node:Node,
                        title:String,
                        overview:String,
                        release_date:String,
                        poster:String,
                        runtime:String,
                        rating:String,
                        genre:String,
                        cast:String,
                        director:String,
                        result: @escaping(Error?) -> ()
        )
    {
        let record = CKRecord(recordType: "MetaInfo")
        record.setValue(node.path!, forKey: "path")
        record.setValue(cast, forKey: "cast")
        record.setValue(director, forKey: "director")
        record.setValue(genre, forKey: "genre")
        record.setValue(overview, forKey: "overview")
        record.setValue(poster, forKey: "poster")
        record.setValue(rating, forKey: "rating")
        record.setValue(release_date, forKey: "release_date")
        record.setValue(runtime, forKey: "runtime")
        record.setValue(title, forKey: "title")
        
        publicDB!.save(record, completionHandler: { cloudRecord, error in
            DispatchQueue.main.async {
                if error != nil {
                    result(error)
                } else {
                    self.clearInfoForNode(node)
                    var info = self.getInfo(node.path!)
                    if info == nil {
                        info = NSEntityDescription.insertNewObject(forEntityName: "MetaInfo", into: self.managedObjectContext) as? MetaInfo
                        info!.path = node.path!
                    }
                    info!.recordName = cloudRecord!.recordID.recordName
                    info!.zoneName = cloudRecord!.recordID.zoneID.zoneName
                    info!.ownerName = cloudRecord!.recordID.zoneID.ownerName
                    info!.title = title
                    info!.overview = overview
                    info!.release_date = release_date
                    info!.poster = poster
                    info!.runtime = runtime
                    info!.rating = rating
                    info!.genre = genre
                    info!.cast = cast
                    info!.director = director
                    
                    info!.node = node
                    node.info = info
                    self.saveContext()
                    
                    result(nil)
                }
            }
        })
    }
    
    func clearInfoForNode(_ node:Node) {
        if node.info == nil {
            return
        }
        managedObjectContext.delete(node.info!)
        node.info = nil
        saveContext()
        
        let recordZoneID = CKRecordZoneID(zoneName: node.info!.zoneName!, ownerName: node.info!.ownerName!)
        let recordID = CKRecordID(recordName: node.info!.recordName!, zoneID: recordZoneID)
        publicDB!.delete(withRecordID: recordID, completionHandler: { record, error in
            DispatchQueue.main.async {
                if error != nil {
                    print(error!)
                }
            }
        })
    }
    
    func clearInfo(_ forNode:Node, result: @escaping(Error?) -> ()) {
        if forNode.info == nil {
            result(nil)
            return
        }
        
        let recordZoneID = CKRecordZoneID(zoneName: forNode.info!.zoneName!, ownerName: forNode.info!.ownerName!)
        let recordID = CKRecordID(recordName: forNode.info!.recordName!, zoneID: recordZoneID)
        publicDB!.delete(withRecordID: recordID, completionHandler: { record, error in
            DispatchQueue.main.async {
                if error != nil {
                    result(error)
                } else {
                    self.clearInfoForNode(forNode)
                    result(nil)
                }
            }
        })
    }

}

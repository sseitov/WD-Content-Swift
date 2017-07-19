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

let refreshNotification = Notification.Name("REFRESH")
let refreshNodeNotification = Notification.Name("REFRESH_NODE")

func generateUDID() -> String {
    return UUID().uuidString
}

@objc class Model: NSObject {
    
    static let shared = Model()

    class func releaseDate(_ text:String) -> String {
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
    
    class func year(_ text:String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        if let date = formatter.date(from: text) {
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "yyyy"
            return yearFormatter.string(from: date)
        } else {
            return ""
        }
    }
    
    class func isValidMediaType(name:String) -> Bool {
        let ext = (name as NSString).pathExtension
        let movieExtensions = ["mkv", "avi", "iso", "ts", "mov", "m4v", "mpg", "mpeg", "wmv", "mp4"]
        return movieExtensions.contains(ext)
    }
    
    var cloudDB: CKDatabase?

    private override init() {
        super.init()
        
        let container = CKContainer.default()
        cloudDB = container.privateCloudDatabase

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
    
    @objc func refreshShares(_ result: @escaping(Error?) -> ()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Connection", predicate: predicate)
        
        cloudDB!.perform(query, inZoneWith: nil) { [unowned self] results, error in
            
            guard error == nil else {
                DispatchQueue.main.async {
                    print("Cloud Query Error - Refresh: \(error!.localizedDescription)")
                    result(error)
                }
                return
            }
            
            DispatchQueue.main.async {
                for record in results! {
                    self.addShare(record)
                }
                result(nil)
            }
        }
    }
    
    // MARK: - Share table
    
    func addShare(_ record:CKRecord) {
        if let ip = record["ip"] as? String, let name = record["name"] as? String {
            var share = getShare(ip: ip, name: name)
            if share == nil {
                share = NSEntityDescription.insertNewObject(forEntityName: "Share", into: managedObjectContext) as? Share
                share!.ip = ip
                share!.name = name
                if let port = record["port"] as? String, let portNum = Int(port), let user = record["user"] as? String, let password = record["password"] as? String {
                    
                    share!.recordName = record.recordID.recordName
                    share!.zoneName = record.recordID.zoneID.zoneName
                    share!.ownerName = record.recordID.zoneID.ownerName
                    share!.port = Int32(portNum)
                    share!.user = user
                    share!.password = password
                    saveContext()
                }
            }
        }
    }

    func createShare(name:String, ip:String, port:Int32, user:String, password:String, result: @escaping(Share?) -> ()) {
        
        if let connection = getShare(ip:ip, name:name) {
            result(connection)
        }
        
        let record = CKRecord(recordType: "Connection")
        record.setValue(name, forKey: "name")
        record.setValue(ip, forKey: "ip")
        record.setValue("\(port)", forKey: "port")
        record.setValue(user, forKey: "user")
        record.setValue(password, forKey: "password")
        
        cloudDB!.save(record, completionHandler: { cloudRecord, error in
            DispatchQueue.main.async {
                if error != nil {
                    result(nil)
                } else {
                    let share = NSEntityDescription.insertNewObject(forEntityName: "Share", into: self.managedObjectContext) as! Share
                    share.recordName = cloudRecord!.recordID.recordName
                    share.zoneName = cloudRecord!.recordID.zoneID.zoneName
                    share.ownerName = cloudRecord!.recordID.zoneID.ownerName
                    share.name = name
                    share.ip = ip
                    share.port = port
                    share.user = user
                    share.password = password
                    self.saveContext()
                    result(share)
                }
            }
        })
    }
    
    func deleteShare(_ share:Share, result: @escaping(Error?) -> ()) {

        clearShareInfo(share)
        
        let recordZoneID = CKRecordZoneID(zoneName: share.zoneName!, ownerName: share.ownerName!)
        let recordID = CKRecordID(recordName: share.recordName!, zoneID: recordZoneID)
        
        cloudDB!.delete(withRecordID: recordID, completionHandler: { record, error in
            DispatchQueue.main.async {
                if error != nil {
                    result(error)
                } else {
                    self.managedObjectContext.delete(share)
                    self.saveContext()
                    result(nil)
                }
            }
        })
    }
    
    func getShareByIp(_ ip:String) -> Share? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Share")
        fetchRequest.predicate = NSPredicate(format: "ip == %@", ip)
        if let share = try? managedObjectContext.fetch(fetchRequest).first as? Share {
            return share
        } else {
            return nil
        }
    }
    
    func getShare(ip:String, name:String) -> Share? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Share")
        let pred1 = NSPredicate(format: "ip == %@", ip)
        let pred2 = NSPredicate(format: "name == %@", name)
        fetchRequest.predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [pred1, pred2])
        if let share = try? managedObjectContext.fetch(fetchRequest).first as? Share {
            return share
        } else {
            return nil
        }
    }
    
    func allShares() -> [Share] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Share")
        let sort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        if let share = try? managedObjectContext.fetch(fetchRequest) as! [Share] {
            return share
        } else {
            return []
        }
    }
    
    // MARK: - Node table

    func nodes(byRoot:Node) -> [Node] {
        let connection = SMBConnection()
        if connection.connect(to: byRoot.share!.ip!,
                              port: byRoot.share!.port,
                              user: byRoot.share!.user!,
                              password: byRoot.share!.password!) {
            let content = connection.folderContents(byRoot: byRoot) as! [Node]
            return content.sorted(by: { node1, node2 in
                if !node1.directory && !node2.directory {
                    return node1.name < node2.name
                } else if node1.directory && node2.directory {
                    return node1.name < node2.name
                } else if !node1.directory {
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
    
    // MARK: - MetaInfo table
    
    func getInfoForNode(_ node:Node) -> MetaInfo? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MetaInfo")
        fetchRequest.predicate = NSPredicate(format: "path == %@", node.filePath)
        if let info = try? managedObjectContext.fetch(fetchRequest).first as? MetaInfo {
            return info
        } else {
            return nil
        }
    }

    func setAudioChannel(_ info:MetaInfo, channel:Int) {
        let recordZoneID = CKRecordZoneID(zoneName: info.zoneName!, ownerName: info.ownerName!)
        let recordID = CKRecordID(recordName: info.recordName!, zoneID: recordZoneID)
        cloudDB?.fetch(withRecordID: recordID, completionHandler: { record, error in
            if error == nil && record != nil {
                record!.setValue(Date(), forKey: "updated")
                record!.setValue(Int(info.audioChannel), forKey: "audioChannel")
                record!.setValue(Int(1), forKey: "wasViewed")
                self.cloudDB!.save(record!, completionHandler: { _, error in
                    DispatchQueue.main.async {
                        info.audioChannel = Int32(channel)
                        info.wasViewed = true
                        self.saveContext()
                    }
                })
            }
        })
    }
    
    func setSubtitleChannel(_ info:MetaInfo, channel:Int) {
        info.subtitleChannel = Int32(channel)
        info.wasViewed = true
        self.saveContext()
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
        record.setValue(node.share!.ip!, forKey: "share")
        record.setValue(node.filePath, forKey: "path")
        record.setValue(cast, forKey: "cast")
        record.setValue(director, forKey: "director")
        record.setValue(genre, forKey: "genre")
        record.setValue(overview, forKey: "overview")
        record.setValue(poster, forKey: "poster")
        record.setValue(rating, forKey: "rating")
        record.setValue(release_date, forKey: "release_date")
        record.setValue(runtime, forKey: "runtime")
        record.setValue(title, forKey: "title")
        record.setValue(Date(), forKey: "updated")
        record.setValue(0, forKey: "audioChannel")
        record.setValue(0, forKey: "wasViewed")
        
        cloudDB!.save(record, completionHandler: { cloudRecord, error in
            DispatchQueue.main.async {
                if error != nil {
                    result(error)
                } else {
                    var info = self.getInfoForNode(node)
                    if info == nil {
                        info = NSEntityDescription.insertNewObject(forEntityName: "MetaInfo", into: self.managedObjectContext) as? MetaInfo
                        info!.path = node.filePath
                        info!.share = node.share!.ip!
                    }
                    info!.modificationDate = NSDate()
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
                    info!.audioChannel = -1
                    info!.wasViewed = false
                    self.saveContext()
                    
                    result(nil)
                }
            }
        })
    }
    
    func updateInfoForNode(_ node:Node) {
        let predicate = NSPredicate(format: "path == %@", node.filePath)
        let query = CKQuery(recordType: "MetaInfo", predicate: predicate)
        
        cloudDB!.perform(query, inZoneWith: nil, completionHandler: { records, error in
            DispatchQueue.main.async {
                if error != nil {
                    print(error!)
                } else if records != nil, let record = records!.first {
                    if node.info != nil {
                        if let date = node.info!.modificationDate as Date?, let recordDate = record.modificationDate {
                            if recordDate >= date { // actual date
                                return
                            }
                        }
                    }
                    var info = self.getInfoForNode(node)
                    if info == nil {
                        info = NSEntityDescription.insertNewObject(forEntityName: "MetaInfo", into: self.managedObjectContext) as? MetaInfo
                        info!.path = record["path"] as? String
                        info!.share = record["share"] as? String
                    }
                    info!.modificationDate = record.modificationDate != nil ? record.modificationDate as NSDate? : record.creationDate as NSDate?
                    info!.recordName = record.recordID.recordName
                    info!.zoneName = record.recordID.zoneID.zoneName
                    info!.ownerName = record.recordID.zoneID.ownerName
                    info!.title = record["title"] as? String
                    info!.overview = record["overview"] as? String
                    info!.release_date = record["release_date"] as? String
                    info!.poster = record["poster"] as? String
                    info!.runtime = record["runtime"] as? String
                    info!.rating = record["rating"] as? String
                    info!.genre = record["genre"] as? String
                    info!.cast = record["cast"] as? String
                    info!.director = record["director"] as? String
                    if let channel = record["audioChannel"] as? Int {
                        info!.audioChannel = Int32(channel)
                    } else {
                        info!.audioChannel = -1
                    }
                    if let wasVieved = record["wasViewed"] as? Int {
                        info!.wasViewed = wasVieved != 0
                    } else {
                        info!.wasViewed = false
                    }

                    self.saveContext()
                    NotificationCenter.default.post(name: refreshNodeNotification, object: node)
                }
            }
        })
    }
    
    func clearInfo(_ info:MetaInfo, result: @escaping(Error?) -> ()) {
        let recordZoneID = CKRecordZoneID(zoneName: info.zoneName!, ownerName: info.ownerName!)
        let recordID = CKRecordID(recordName: info.recordName!, zoneID: recordZoneID)
        cloudDB!.delete(withRecordID: recordID, completionHandler: { record, error in
            DispatchQueue.main.async {
                if error != nil {
                    result(error)
                } else {
                    self.managedObjectContext.delete(info)
                    self.saveContext()
                    result(nil)
                }
            }
        })
    }

    func clearShareInfo(_ share:Share) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MetaInfo")
        fetchRequest.predicate = NSPredicate(format: "share == %@", share.ip!)
        if let infos = try? managedObjectContext.fetch(fetchRequest) as! [MetaInfo] {
            for info in infos {
                self.managedObjectContext.delete(info)
            }
            self.saveContext()
        }

        let predicate = NSPredicate(format: "share == %@", share.ip!)
        let query = CKQuery(recordType: "MetaInfo", predicate: predicate)
        cloudDB!.perform(query, inZoneWith: nil) { [unowned self] results, error in
            if error == nil {
                for record in results! {
                    self.cloudDB!.delete(withRecordID: record.recordID, completionHandler: { _, _ in
                    })
                }
            }
        }
    }
}

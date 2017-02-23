//
//  Node+CoreDataProperties.swift
//  WD Content
//
//  Created by Сергей Сейтов on 23.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import Foundation
import CoreData


extension Node {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Node> {
        return NSFetchRequest<Node>(entityName: "Node");
    }

    @NSManaged public var isFile: Bool
    @NSManaged public var name: String?
    @NSManaged public var path: String?
    @NSManaged public var lastAudioChannel: Int16
    @NSManaged public var wasViewed: Bool
    @NSManaged public var uid: String?
    @NSManaged public var childs: NSSet?
    @NSManaged public var parent: Node?
    @NSManaged public var info: MetaInfo?
    @NSManaged public var connection: Connection?

}

// MARK: Generated accessors for childs
extension Node {

    @objc(addChildsObject:)
    @NSManaged public func addToChilds(_ value: Node)

    @objc(removeChildsObject:)
    @NSManaged public func removeFromChilds(_ value: Node)

    @objc(addChilds:)
    @NSManaged public func addToChilds(_ values: NSSet)

    @objc(removeChilds:)
    @NSManaged public func removeFromChilds(_ values: NSSet)

}

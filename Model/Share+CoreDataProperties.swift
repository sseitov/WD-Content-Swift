//
//  Share+CoreDataProperties.swift
//  WD Content
//
//  Created by Сергей Сейтов on 27.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import Foundation
import CoreData


extension Share {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Share> {
        return NSFetchRequest<Share>(entityName: "Share");
    }

    @NSManaged public var ip: String?
    @NSManaged public var ownerName: String?
    @NSManaged public var password: String?
    @NSManaged public var port: Int32
    @NSManaged public var recordName: String?
    @NSManaged public var user: String?
    @NSManaged public var zoneName: String?
    @NSManaged public var name: String?

}

//
//  Share+CoreDataClass.swift
//  WD Content
//
//  Created by Сергей Сейтов on 27.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import Foundation
import CoreData


public class Share: NSManagedObject {

    func displayName() -> String {
        if path == nil || path! == "" {
            return name!
        } else {
            let comps = path!.components(separatedBy: "//")
            if let title = comps.last {
                return title
            } else {
                return name!
            }
        }
    }
}

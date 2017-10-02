//
//  Node.swift
//  WD Content
//
//  Created by Сергей Сейтов on 27.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class Node: NSObject {

    @objc var name:String = ""
    @objc var filePath:String = ""
    @objc var directory:Bool = true
    @objc var parent:Node?
    @objc var info:MetaInfo?
    @objc var share:Share?
    @objc var selectedIndexPath:IndexPath?

    @objc init(share: Share) {
        super.init()
        
        self.share = share
        self.name = share.name!
        var path = share.path
        if path == nil {
            path = ""
        }
        self.filePath = "//\(name)/\(path!)"
        self.directory = true;
    }

    @objc init(name: String) {
        super.init()
        
        self.name = name
        self.filePath = "//\(name)/"
        self.directory = true;
    }
    
    @objc init(name:String, isDir:Bool, parent:Node) {
        super.init()

        self.parent = parent
        self.name = name
        self.filePath = "\(parent.filePath)/\(name)"
        self.directory = isDir
    }
    
    @objc func dislayName() -> String {
        if parent == nil {
            let path = self.filePath.replacingOccurrences(of: "//\(name)/", with: "")
            let comps = path.components(separatedBy: "/")
            if let display = comps.last {
                return display.replacingOccurrences(of: "_", with: " ", options: [], range: nil)
            } else {
                return name.replacingOccurrences(of: "_", with: " ", options: [], range: nil)
            }
        } else {
            let display = (name as NSString).deletingPathExtension
            return display.replacingOccurrences(of: "_", with: " ", options: [], range: nil)
        }
    }
    
    @objc class func shareNameFromPath(_ path:String) -> String {
        var share = path as NSString

        if share.substring(to: 2) == "//" {
            share = share.substring(from: 2) as NSString
        } else if share.substring(to: 1) == "//" {
            share = share.substring(from: 1) as NSString
        }
        
        let range = share.range(of: "/")
        if range.location != NSNotFound {
            share = share.substring(with: NSRange(location: 0, length: range.location)) as NSString
        }
        
        return share as String
    }
    
    @objc class func filePathExcludingSharePathFromPath(_ path:String) -> String {
        var filePath = path as NSString
        
        if filePath.substring(to: 2) == "//" || filePath.substring(to: 2) == "\\\\" {
            filePath = filePath.substring(from: 2) as NSString
        } else if filePath.substring(to: 1) == "/" || filePath.substring(to: 1) == "\\" {
            filePath = filePath.substring(from: 1) as NSString
        }
        
        var range = filePath.range(of: "/")
        if range.location == NSNotFound {
            range = filePath.range(of: "\\")
        }
        if range.location != NSNotFound {
            filePath = filePath.substring(from: (range.location + 1)) as NSString
        }
        
        return filePath as String
    }
}

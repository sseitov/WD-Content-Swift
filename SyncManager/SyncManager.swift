//
//  SyncManager.swift
//  Glucograph
//
//  Created by Sergey Seitov on 18.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class SyncManager: NSObject {
    
    static let shared = SyncManager()
    
    private var internetReachability:Reachability?
    private var networkStatus:NetworkStatus = NotReachable
    
    private override init() {
        super.init()
        
        internetReachability = Reachability.forInternetConnection()
        if internetReachability != nil {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.reachabilityChanged(_:)),
                                                   name: NSNotification.Name.reachabilityChanged,
                                                   object: nil)
            networkStatus = internetReachability!.currentReachabilityStatus()
            internetReachability!.startNotifier()
        }
    }
    
    // MARK: - Reachability
    
    func syncAvailable() -> Bool {
        return syncAvailable(networkStatus)
    }
    
    private func syncAvailable(_ status:NetworkStatus) -> Bool {
        return status == ReachableViaWiFi
    }
    
    @objc  func reachabilityChanged(_ notify:Notification) {
        if let currentReachability = notify.object as? Reachability {
            let newStatus = currentReachability.currentReachabilityStatus()
            if !syncAvailable(networkStatus) && syncAvailable(newStatus) {
                Model.shared.refreshShares({ error in
                    if error != nil {
                        print(error!.localizedDescription)
                    }
                })
            }
            networkStatus = newStatus
        }
    }
    
}

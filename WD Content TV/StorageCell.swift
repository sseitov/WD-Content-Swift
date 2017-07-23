//
//  StorageCell.swift
//  WD Content
//
//  Created by Сергей Сейтов on 22.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class StorageCell: UICollectionViewCell {
    
    @IBOutlet weak var nameView: UILabel!
    
    var name:String? {
        didSet {
            nameView.text = name
        }
    }
    
    override var canBecomeFocused : Bool {
        return true
    }
    
    func becomeFocusedUsingAnimationCoordinator(_ coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.nameView.textColor = UIColor.white
            self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOffset = CGSize(width: 10, height: 50)
            self.layer.shadowOpacity = 0.5
            self.layer.shadowRadius = 20
        }) { () -> Void in
        }
    }
    
    func resignFocusUsingAnimationCoordinator(_ coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.nameView.textColor = UIColor.black
            self.transform = CGAffineTransform.identity
            self.layer.shadowColor = nil
            self.layer.shadowOffset = CGSize.zero
        }) { () -> Void in
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        guard let nextFocusedView = context.nextFocusedView else { return }
        
        if nextFocusedView == self {
            self.becomeFocusedUsingAnimationCoordinator(coordinator)
        } else {
            self.resignFocusUsingAnimationCoordinator(coordinator)
        }
    }
}

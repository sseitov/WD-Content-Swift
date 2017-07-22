//
//  StorageCell.swift
//  WD Content
//
//  Created by Сергей Сейтов on 22.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class StorageCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var textConstraint: NSLayoutConstraint!
    
    var name:String? {
        didSet {
            nameView.text = name
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.image.adjustsImageWhenAncestorFocused = true
                self.nameView.textColor = UIColor.white
                self.textConstraint.constant = -30
            } else {
                self.image.adjustsImageWhenAncestorFocused = false
                self.nameView.textColor = UIColor.black
                self.textConstraint.constant = 2
            }
        }, completion: nil)
        
    }
}

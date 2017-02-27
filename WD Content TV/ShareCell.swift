//
//  ShareCell.swift
//  WD Content
//
//  Created by Сергей Сейтов on 29.12.16.
//  Copyright © 2016 Sergey Seitov. All rights reserved.
//

import UIKit

class ShareCell: UICollectionViewCell {
    
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var textView: UILabel!
	@IBOutlet weak var textConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkView: UIImageView!

	var node:Node? {
		didSet {
			if !node!.directory {
				if node!.info == nil {
					textView.text = node!.name
					imageView.image = UIImage(named: "movie")
				} else {
					textView.text = node!.info!.title!
					if node!.info!.poster != nil {
						let url = URL(string: node!.info!.poster!)
						imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
					} else {
						imageView.image = UIImage(named: "movie")
					}
				}
                Model.shared.updateInfoForNode(node!)
			} else {
				textView.text = node!.name
                if node!.parent == nil {
                    imageView.image = UIImage(named: "share")
                } else {
                    imageView.image = UIImage(named: "sharedFolder")
                }
			}
            self.checkView.alpha = checked() ? 1 : 0
		}
	}
	
    private func checked() -> Bool {
        return false
    }
    
	override func awakeFromNib() {
		super.awakeFromNib()
		imageView.adjustsImageWhenAncestorFocused = false
		imageView.clipsToBounds = false
		textView.clipsToBounds = false
		textView.alpha = 0.3
        self.checkView.alpha = 0
	}
	
	override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {

		coordinator.addCoordinatedAnimations({
			if self.isFocused {
                if self.checked() {
                    self.checkConstraint.constant = -40
                }
				self.textView.alpha = 1.0
				self.textConstraint.constant = -30
				self.imageView.adjustsImageWhenAncestorFocused = true
			}
			else {
                if self.checked() {
                    self.checkConstraint.constant = -20
                }
				self.textView.alpha = 0.3
				self.textConstraint.constant = 0
				self.imageView.adjustsImageWhenAncestorFocused = false
			}
		}, completion: nil)

	}
}

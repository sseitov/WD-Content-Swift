//
//  NodeCell.swift
//  WD Content
//
//  Created by Sergey Seitov on 23.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

protocol NodeCellDelegate {
    func reloadInfoFor(node:Node?)
}

class NodeCell: UITableViewCell {

    var node:Node? {
        didSet {
            setupInfo()
            if !node!.directory, node?.info == nil {
                updateInfo()
            }
        }
    }
    var delegate:NodeCellDelegate?
    
    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var nameView: UILabel!
    @IBOutlet weak var dateView: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionView.backgroundColor = UIColor.clear
        nameView.textColor = UIColor.white
        dateView.textColor = UIColor.white
    }
    
    // MARK: - Update Node Info

    func updateInfo() {
        Model.shared.updateInfoForNode(node!, complete: { info in
            if info != nil {
                self.node?.info = info
                self.updateInfo()
                self.delegate?.reloadInfoFor(node: self.node)
            }
        })
    }
    
    func setupInfo() {
        if node!.directory {
            typeView.image = UIImage(named: "folderIcon")
            nameView.text = node?.dislayName()
            dateView.text = ""
        } else {
            if node?.info != nil {
                if node!.info!.wasViewed {
                    typeView.image = UIImage(named: "viewed_on")
                } else {
                    typeView.image = UIImage(named: "viewed_off")
                }
                nameView.text = node!.info?.title
                if node?.info?.release_date != nil {
                    dateView.text = Model.year(node!.info!.release_date!)
                } else {
                    dateView.text = ""
                }
            } else {
                typeView.image = UIImage(named: "viewed_off")
                nameView.text = node?.dislayName()
                dateView.text = ""
            }
        }
    }
    
    // MARK: - Focus Control

    override var canBecomeFocused : Bool {
        return true
    }
    
    func becomeFocusedUsingAnimationCoordinator(_ coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.selectionView.backgroundColor = UIColor.mainColor()
        }) { () -> Void in
        }
    }
    
    func resignFocusUsingAnimationCoordinator(_ coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.selectionView.backgroundColor = UIColor.clear
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

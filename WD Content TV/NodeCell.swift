//
//  NodeCell.swift
//  WD Content
//
//  Created by Sergey Seitov on 23.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

protocol NodeCellDelegate {
    func didUpdateInfo(_ node:Node)
}

class NodeCell: UITableViewCell {

    var node:Node? {
        didSet {
            updateInfo()
            Model.shared.updateInfoForNode(node!)
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshNode(notyfy:)),
                                               name: refreshNodeNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Update Node Info

    func refreshNode(notyfy:Notification) {
        if let theNode = notyfy.object as? Node, theNode == node {
            node?.info = Model.shared.getInfoForNode(theNode)
            if self.isFocused {
                self.delegate?.didUpdateInfo(self.node!)
            }
        }
    }

    func updateInfo() {
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
            self.nameView.textColor = UIColor.white
            self.dateView.textColor = UIColor.white
        }) { () -> Void in
            self.delegate?.didUpdateInfo(self.node!)
        }
    }
    
    func resignFocusUsingAnimationCoordinator(_ coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.selectionView.backgroundColor = UIColor.clear
            self.nameView.textColor = UIColor.black
            self.dateView.textColor = UIColor.black
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if !selected {
            self.selectionView.backgroundColor = UIColor.clear
            self.nameView.textColor = UIColor.black
            self.dateView.textColor = UIColor.black
        }
    }
}

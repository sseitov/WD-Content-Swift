//
//  ContentCell.swift
//  WD Content
//
//  Created by Сергей Сейтов on 24.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class ContentCell: UICollectionViewCell {
    
    @IBOutlet weak var nodeImage: UIImageView!
    @IBOutlet weak var nodeName: UILabel!
    @IBOutlet weak var cardView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.setupBorder(UIColor.clear, radius: 20)
    }
    
    var node:Node? {
        didSet {
            if !node!.directory {
                cardView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
                updateNode()
                Model.shared.updateInfoForNode(node!, complete: {
                    self.updateNode()
                })
            } else {
                cardView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                nodeImage.image = UIImage(named: "folder")
                nodeName.text = node!.dislayName().uppercased()
            }
        }
    }
    
    func updateNode() {
        node?.info = Model.shared.getInfoForNode(node!)
        if node!.info == nil {
            nodeName.text = node!.dislayName()
            nodeImage.image = UIImage(named: "file")
        } else {
            let dateText = "\n(\(Model.year(node!.info!.release_date!)))"
            nodeName.text = node!.info!.title! + dateText
            if node!.info!.poster != nil {
                let url = URL(string: node!.info!.poster!)
                nodeImage.sd_setImage(with: url, placeholderImage: UIImage(named: "file"))
            } else {
                nodeImage.image = UIImage(named: "file")
            }
        }
    }
}

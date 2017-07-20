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
    }
    
    var node:Node? {
        didSet {
            if !node!.directory {
                cardView.setupBorder(UIColor.black, radius: 20, width: 5)
                node?.info = Model.shared.getInfoForNode(node!)
                if node!.info == nil {
                    nodeName.text = node!.dislayName()
                    nodeImage.image = UIImage(named: "file")
                } else {
                    let style = NSMutableParagraphStyle()
                    style.lineBreakMode = .byWordWrapping
                    style.alignment = .center
                    let text = NSMutableAttributedString(string: node!.info!.title!,
                                                         attributes: [NSFontAttributeName : UIFont.mainFont(15),
                                                                      NSParagraphStyleAttributeName: style])
                    let dateText = "\n(\(Model.year(node!.info!.release_date!)))"
                    text.append(NSMutableAttributedString(string: dateText,
                                                          attributes: [NSFontAttributeName : UIFont.condensedFont(15)]))
                    nodeName.attributedText = text
                    if node!.info!.poster != nil {
                        let url = URL(string: node!.info!.poster!)
                        nodeImage.sd_setImage(with: url, placeholderImage: UIImage(named: "file"))
                    } else {
                        nodeImage.image = UIImage(named: "file")
                    }
                }
                Model.shared.updateInfoForNode(node!)
            } else {
                cardView.setupBorder(UIColor.clear, radius: 20)
                nodeImage.image = UIImage(named: "folder")
                nodeName.attributedText = NSMutableAttributedString(string: node!.dislayName().uppercased(),
                                                     attributes: [NSFontAttributeName : UIFont.condensedFont(15)])
            }
        }
    }
}

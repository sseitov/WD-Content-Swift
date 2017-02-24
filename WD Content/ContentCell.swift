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

    var node:Node? {
        didSet {
            if node!.isFile {
                if node!.info == nil {
                    nodeName.text = node!.name!
                    nodeImage.image = UIImage(named: "file")
                } else {
                    let text = NSMutableAttributedString(string: node!.info!.title!,
                                                         attributes: [NSFontAttributeName : UIFont.mainFont(15)])
                    let dateText = " (\(year(node!.info!.release_date!)))"
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
            } else {
                nodeImage.image = UIImage(named: "folder")
                nodeName.text = node!.name
            }
        }
    }
}

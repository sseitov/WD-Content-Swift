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
                nodeImage.image = UIImage(named: "file")
            } else {
                nodeImage.image = UIImage(named: "folder")
            }
            nodeName.text = node!.name
        }
    }
}

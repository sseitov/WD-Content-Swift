//
//  CoverView.swift
//  WD Content
//
//  Created by Sergey Seitov on 23.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class CoverView: UIView {
    
    var node:Node? {
        didSet {
            if node != nil && !node!.directory && node!.info != nil {
                directorLabel.text = "DIRECTOR"
                directorView.text = node?.info?.director
                runtimeView.text = node?.info?.runtime
            } else {
                directorLabel.text = ""
                directorView.text = ""
                runtimeView.text = ""
            }
            if node == nil {
                coverView.image = nil
            } else {
                if node!.directory {
                    coverView.image = UIImage(named: "folder")
                } else {
                    if node!.info != nil {
                        if node!.info?.poster != nil, let url = URL(string: node!.info!.poster!) {
                            coverView.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
                        } else {
                            coverView.image = UIImage(named: "movie")
                        }
                    } else {
                        coverView.image = UIImage(named: "movie")
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var directorLabel: UILabel!
    @IBOutlet weak var directorView: UILabel!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var runtimeView: UILabel!
    
}

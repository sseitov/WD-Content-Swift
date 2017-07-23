//
//  InfoView.swift
//  WD Content
//
//  Created by Sergey Seitov on 23.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class InfoCell: UITableViewCell {
    @IBOutlet weak var infoTitle: UILabel!
    @IBOutlet weak var infoText: UITextView!
}

class InfoView: UIView, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var infoTable: UITableView!

    var node:Node? {
        didSet {
            infoTable.reloadData()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if node != nil && !node!.directory && node!.info != nil {
            return 3
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "info", for: indexPath) as! InfoCell
        switch indexPath.row {
        case 0:
            cell.infoTitle.text = "GENRES"
            cell.infoText?.text = node?.info?.genre
        case 1:
            cell.infoTitle.text = "CAST"
            cell.infoText?.text = node?.info?.cast
        default:
            cell.infoTitle.text = "OVERVIEW"
            cell.infoText?.text = node?.info?.overview
        }
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 120
        case 1:
            return 165
        default:
            return infoTable.frame.size.height - 285
        }
    }
}

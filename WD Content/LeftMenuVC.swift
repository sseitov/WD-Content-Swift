//
//  LeftMenuVC.swift
//  WD Content
//
//  Created by Сергей Сейтов on 24.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class LeftMenuVC: AMSlideMenuLeftTableViewController {

    @IBOutlet weak var titleItem: UINavigationItem!
    
    var nodes:[Node] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        nodes = Model.shared.nodes(byRoot: nil)
        navigationController?.navigationBar.tintColor = UIColor.mainColor()
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        label.font = UIFont.condensedFont()
        label.textAlignment = .center
        label.text = "My Shares"
        label.textColor = UIColor.white
        titleItem.titleView = label
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count == 0 ? 1 : nodes.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        if nodes.count == 0 {
            cell.textLabel?.text = "Empty list"
            cell.contentView.backgroundColor = UIColor.clear
            cell.backgroundColor = UIColor.clear
        } else {
            cell.textLabel?.text = nodes[indexPath.row].name!
            cell.contentView.backgroundColor = UIColor.white
            cell.backgroundColor = UIColor.white
        }
        cell.textLabel?.font = UIFont.condensedFont()
        cell.textLabel?.textColor = UIColor.mainColor()
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "content" {
            return nodes.count > 0
        } else {
            return true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "content" {
            
        }
    }

}

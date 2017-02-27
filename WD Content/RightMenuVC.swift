//
//  LeftMenuVC.swift
//  WD Content
//
//  Created by Сергей Сейтов on 24.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import AMSlideMenu
import SVProgressHUD

class RightMenuVC: AMSlideMenuRightTableViewController {

    @IBOutlet weak var titleItem: UINavigationItem!
    
    var nodes:[Node] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        nodes = Model.shared.nodes(byRoot: nil)
        navigationController?.navigationBar.tintColor = UIColor.mainColor()
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        label.font = UIFont.condensedFont()
        label.textAlignment = .center
        label.text = "MY SHARES"
        label.textColor = UIColor.white
        titleItem.titleView = label

        refresh()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refresh),
                                               name: refreshNotification,
                                               object: nil)

    }

    func refresh() {
        SVProgressHUD.show(withStatus: "Refresh...")
        Model.shared.refreshConnections({ error in
            SVProgressHUD.dismiss()
            if error != nil {
                self.showMessage("Cloud refresh error: \(error!)", messageType: .information)
            }
            self.nodes = Model.shared.nodes(byRoot: nil)
            self.tableView.reloadData()
        })
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
            cell.imageView?.image = nil
        } else {
            cell.textLabel?.text = nodes[indexPath.row].name!
            cell.contentView.backgroundColor = UIColor.white
            cell.backgroundColor = UIColor.white
            cell.imageView?.image = UIImage(named: "iosShare")
        }
        cell.textLabel?.font = UIFont.condensedFont()
        cell.textLabel?.textColor = UIColor.mainColor()
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return nodes.count > 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            let node = nodes[indexPath.row]
            Model.shared.deleteNode(node)
            nodes.remove(at: indexPath.row)
            if nodes.count > 0 {
                tableView.deleteRows(at: [indexPath], with: .top)
            } else {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
            tableView.endUpdates()
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindToMenu(_ segue: UIStoryboardSegue) {
        mainVC.openRightMenu(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "content" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! ContentController
            if let indexPath = tableView.indexPathForSelectedRow {
                next.parentNode = nodes[indexPath.row]
                UserDefaults.standard.set(indexPath.row, forKey: "lastShare")
                UserDefaults.standard.synchronize()
            } else {
                let index = UserDefaults.standard.integer(forKey: "lastShare")
                if index < nodes.count {
                    next.parentNode = nodes[index]
                } else {
                    next.parentNode = nodes[0]
                }
            }
        }
    }

}

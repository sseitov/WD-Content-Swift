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
    
    var shares:[Share] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        shares = Model.shared.allShares()
        navigationController?.navigationBar.tintColor = UIColor.mainColor()
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        label.font = UIFont.condensedFont()
        label.textAlignment = .center
        label.text = "MOVIES"
        label.textColor = UIColor.white
        titleItem.titleView = label

        refresh()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refresh),
                                               name: refreshNotification,
                                               object: nil)

    }

    @objc func refresh() {
        SVProgressHUD.show(withStatus: "Refresh...")
        Model.shared.refreshShares({ error in
            SVProgressHUD.dismiss()
            if error != nil {
                self.showMessage(error!.localizedDescription, messageType: .error)
            }
            self.shares = Model.shared.allShares()
            self.tableView.reloadData()
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shares.count == 0 ? 1 : shares.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        if shares.count == 0 {
            cell.textLabel?.text = "Empty list"
            cell.contentView.backgroundColor = UIColor.clear
            cell.backgroundColor = UIColor.clear
            cell.imageView?.image = nil
        } else {
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.text = shares[indexPath.row].displayName()
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
        return shares.count > 0
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SVProgressHUD.show(withStatus: "Delete...")
            Model.shared.deleteShare(shares[indexPath.row], result: { error in
                SVProgressHUD.dismiss()
                if error == nil {
                    tableView.beginUpdates()
                    self.shares.remove(at: indexPath.row)
                    if self.shares.count > 0 {
                        tableView.deleteRows(at: [indexPath], with: .top)
                    } else {
                        tableView.reloadRows(at: [indexPath], with: .fade)
                    }
                    tableView.endUpdates()
                } else {
                    self.showMessage("Can not delete share.", messageType: .error)
                }
            })
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
                next.parentNode = Node(share: shares[indexPath.row])
                UserDefaults.standard.set(indexPath.row, forKey: "lastShare")
                UserDefaults.standard.synchronize()
            } else {
                let index = UserDefaults.standard.integer(forKey: "lastShare")
                if index < shares.count {
                    next.parentNode = Node(share: shares[index])
                } else {
                    next.parentNode = Node(share: shares[0])
                }
            }
        }
    }

}

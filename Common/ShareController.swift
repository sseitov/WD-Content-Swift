//
//  ShareController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 13.08.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class ShareController: UITableViewController {

    var connection:SMBConnection?
    var target:ServiceHost?
    var shareName:String?

    private var currentNode:Node?
    private var folders:[Node] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    #if TV
        let backTap = UITapGestureRecognizer(target: self, action: #selector(self.goBack))
        backTap.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        self.view.addGestureRecognizer(backTap)
    #endif
        currentNode = Node(name: shareName!)
        refresh()
    }

    override func goBack() {
        if currentNode?.parent == nil {
            super.goBack()
        } else {
            currentNode = currentNode?.parent
            refresh()
        }
    }
    
    func refresh() {
        #if IOS
            setupTitle(currentNode!.name, color: UIColor.lightGray)
            setupBackButton()
        #else
            self.title = currentNode!.name
            self.view.backgroundColor = UIColor.white
        #endif
        
        if let ff = connection?.folders(byRoot: currentNode) as? [Node] {
            folders = ff
        } else {
            folders = []
        }
        for folder in folders {
            folder.parent = currentNode
        }
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folders.count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let name = folders[indexPath.row].name
        cell.textLabel!.text = name.replacingOccurrences(of: "_", with: " ")
        cell.textLabel?.font = UIFont.mainFont()
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.textAlignment = .center
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentNode = folders[indexPath.row]
        refresh()
    }
    
    @IBAction func createShare(_ sender: Any) {
        let path = currentNode!.filePath.replacingOccurrences(of: "//\(shareName!)//", with: "")
        if Model.shared.getShare(ip: target!.host, name: shareName!, path: path) != nil {
            showMessage("\(shareName!) already was added.", messageType: .information)
        } else {
            SVProgressHUD.show(withStatus: "Add...")
            Model.shared.createShare(name: shareName!, path: path, ip: target!.host, port: target!.port, user: target!.user, password: target!.password, result: { share in
                SVProgressHUD.dismiss()
                #if TV
                    self.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(name: refreshNotification, object: nil)
                    })
                #else
                    NotificationCenter.default.post(name: refreshNotification, object: nil)
                    self.navigationController?.performSegue(withIdentifier: "unwindToMenu", sender: self)
                #endif
            })
        }
    }

}

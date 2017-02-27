//
//  DeviceController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 29.12.16.
//  Copyright © 2016 Sergey Seitov. All rights reserved.
//

import UIKit
import SVProgressHUD

class DeviceController: UITableViewController {

	var target:ServiceHost?
	
	private var connection = SMBConnection()
	private var cashedShare:Share?
	private var shares:[String] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupTitle(target!.name)
    #if IOS
        setupBackButton()
    #endif
		cashedShare = Model.shared.getShareByIp(target!.host)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.cashedShare != nil {
            SVProgressHUD.show(withStatus: "Refresh...")
            DispatchQueue.global().async {
                let connected = self.connection.connect(to: self.cashedShare!.ip!,
                                                    port: self.cashedShare!.port,
                                                    user: self.cashedShare!.user!,
                                                    password: self.cashedShare?.password!)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    if !connected {
                        self.showMessage("Can not connect to \(self.cashedShare!.ip!)", messageType: .error, messageHandler: {
                            self.requestAuth()
                        })
                    } else {
                        self.target?.user = self.cashedShare!.user!
                        self.target?.password = self.cashedShare!.password!
                        self.shares = self.connection.folderContents(byRoot: nil) as! [String]
                        self.tableView.reloadData()
                    }
                }
            }
        } else {
            requestAuth()
        }
    }
    
	func requestAuth() {
    #if IOS
        let alert = PasswordInput.authDialog(title: target!.name, message: "Input credentials", cancelHandler: {
            self.goBack()
        }, acceptHandler: { (user, password) in
            SVProgressHUD.show(withStatus: "Connect...")
            DispatchQueue.global().async {
                let connected = self.connection.connect(to: self.target!.host,
                                                        port: self.target!.port,
                                                        user: user,
                                                        password: password)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    if connected {
                        self.target?.user = user
                        self.target?.password = password
                        self.shares = self.connection.folderContents(byRoot: nil) as! [String]
                        self.tableView.reloadData()
                    } else {
                        self.showMessage("Can not connect.", messageType: .error, messageHandler: {
                            self.goBack()
                        })
                    }
                }
            }
        })
        alert?.show()
    #else
		let alert = UIAlertController(title: target?.name, message: "Input credentials", preferredStyle: .alert)
		var userField:UITextField?
		var passwordField:UITextField?
		alert.addTextField(configurationHandler: { textField in
			textField.keyboardType = .emailAddress
			textField.textAlignment = .center
			textField.placeholder = "user name"
			userField = textField
		})
		alert.addTextField(configurationHandler: { textField in
			textField.keyboardType = .default
			textField.textAlignment = .center
			textField.placeholder = "password"
			textField.isSecureTextEntry = true
			passwordField = textField
		})
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
            self.goBack()
        }))
		alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
            SVProgressHUD.show(withStatus: "Connect...")
            DispatchQueue.global().async {
                let connected = self.connection.connect(to: self.target!.host,
                                                        port: self.target!.port,
                                                        user: userField!.text!,
                                                        password: passwordField!.text!)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    if connected {
                        self.target?.user = userField!.text!
                        self.target?.password = passwordField!.text!
                        self.shares = self.connection.folderContents(byRoot: nil) as! [String]
                        self.tableView.reloadData()
                    } else {
                        self.showMessage("Can not connect.", messageType: .error, messageHandler: {
                            self.goBack()
                        })
                    }
                }
            }
		}))
		present(alert, animated: true, completion: nil)
    #endif
	}
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shares.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel!.text = shares[(indexPath as NSIndexPath).row]
        cell.textLabel?.font = UIFont.mainFont()
        cell.textLabel?.textColor = UIColor.mainColor()
        cell.textLabel?.textAlignment = .center
		return cell
    }
    
#if IOS
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
#endif
    
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let share = shares[indexPath.row];
        SVProgressHUD.show(withStatus: "Add...")
        Model.shared.createShare(name: share, ip: target!.host, port: target!.port, user: target!.user, password: target!.password, result: { share in
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

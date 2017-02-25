//
//  DeviceController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 29.12.16.
//  Copyright © 2016 Sergey Seitov. All rights reserved.
//

import UIKit

class DeviceController: UITableViewController {

	var target:ServiceHost?
	
	private var connection = SMBConnection()
	private var cashedConnection:Connection?
	private var content:[SMBFile] = []
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupTitle(target!.name)
    #if IOS
        setupBackButton()
    #endif
		cashedConnection = Model.shared.getConnection(target!.host)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.cashedConnection != nil {
            SVProgressHUD.show(withStatus: "Refresh...")
            DispatchQueue.global().async {
                let connected = self.connection.connect(to: self.cashedConnection!.ip!,
                                                    port: self.cashedConnection!.port,
                                                    user: self.cashedConnection!.user!,
                                                    password: self.cashedConnection?.password!)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    if !connected {
                        self.showMessage("Can not connect to \(self.cashedConnection!.ip!)", messageType: .error, messageHandler: {
                            self.requestAuth()
                        })
                    } else {
                        self.content = self.connection.folderContents(at: "/") as! [SMBFile]
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
                    if connected {
                        Model.shared.createConnection(ip: self.target!.host,
                                                      port: self.target!.port,
                                                      user: user,
                                                      password: password,
                                                      result:
                            { cashed in
                                SVProgressHUD.dismiss()
                                if cashed == nil {
                                    self.showMessage("Can not create connection.", messageType: .error, messageHandler: {
                                        self.goBack()
                                    })
                                } else {
                                    self.cashedConnection = cashed
                                    self.content = self.connection.folderContents(at: "/") as! [SMBFile]
                                    self.tableView.reloadData()
                                }
                        })
                    } else {
                        SVProgressHUD.dismiss()
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
                    if connected {
                        Model.shared.createConnection(ip: self.target!.host,
                                                      port: self.target!.port,
                                                      user: userField!.text!,
                                                      password: passwordField!.text!,
                                                      result:
                            { cashed in
                                SVProgressHUD.dismiss()
                                if cashed == nil {
                                    self.showMessage("Can not create connection.", messageType: .error, messageHandler: {
                                        self.goBack()
                                    })
                                } else {
                                    self.cashedConnection = cashed
                                    self.content = self.connection.folderContents(at: "/") as! [SMBFile]
                                    self.tableView.reloadData()
                                }
                        })
                    } else {
                        SVProgressHUD.dismiss()
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
        return content.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel!.text = content[(indexPath as NSIndexPath).row].name
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
		let folder = content[indexPath.row];
		_ = Model.shared.addNode(folder, parent: nil, connection: cashedConnection!)
    #if TV
		dismiss(animated: true, completion: {
			NotificationCenter.default.post(name: refreshNotification, object: nil)
		})
    #else
        NotificationCenter.default.post(name: refreshNotification, object: nil)
        self.navigationController?.performSegue(withIdentifier: "unwindToMenu", sender: self)
    #endif
	}
}

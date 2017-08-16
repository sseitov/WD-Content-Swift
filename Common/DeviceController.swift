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
    #if IOS
        setupTitle(target!.name, color: UIColor.lightGray)
        setupBackButton()
    #else
        self.title = target!.name
        self.view.backgroundColor = UIColor.white
    #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cashedShare = Model.shared.getShareByIp(target!.host)
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
            if !self.connection.isConnected() {
                requestAuth()
            }
        }
    }
    
	func requestAuth() {
        let msg = "Input credentials.\nLeave fields empty if used anonymous connection."
    #if IOS
        let alert = PasswordInput.authDialog(title: target!.name, message: msg.uppercased(), cancelHandler: {
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
		let alert = UIAlertController(title: target?.name, message: msg.uppercased(), preferredStyle: .alert)
		var userField:UITextField?
		var passwordField:UITextField?
		alert.addTextField(configurationHandler: { textField in
			textField.keyboardType = .emailAddress
			textField.textAlignment = .center
			textField.placeholder = "user name".uppercased()
			userField = textField
		})
		alert.addTextField(configurationHandler: { textField in
			textField.keyboardType = .default
			textField.textAlignment = .center
			textField.placeholder = "password".uppercased()
			textField.isSecureTextEntry = true
			passwordField = textField
		})
		alert.addAction(UIAlertAction(title: "Ok".uppercased(), style: .default, handler: { _ in
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
        alert.addAction(UIAlertAction(title: "Cancel".uppercased(), style: .destructive, handler: { _ in
            self.goBack()
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
		cell.textLabel!.text = shares[indexPath.row]
        cell.textLabel?.font = UIFont.mainFont()
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.textAlignment = .center
		return cell
    }
    
#if IOS
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
#endif
    
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let shareName = shares[indexPath.row];
        self.performSegue(withIdentifier: "createShare", sender: shareName)

	}
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "createShare" {
            let controller = segue.destination as! ShareController
            controller.target = target
            controller.shareName = sender as? String
        }
    }

}

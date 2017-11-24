//
//  AddShareController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 29.12.16.
//  Copyright © 2016 Sergey Seitov. All rights reserved.
//

import UIKit

class ServiceHost : NSObject {
	var name:String = ""
	var host:String = ""
	var port:Int32 = 0
    var user:String = ""
    var password:String = ""
    
	init(name:String, host:String, port:Int32) {
		super.init()
		self.name = name
		self.host = host
		self.port = port
	}
}

class AddShareController: UITableViewController {

	let serviceBrowser:NetServiceBrowser = NetServiceBrowser()
	var services:[NetService] = []
	var hosts:[ServiceHost] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    #if TV
        self.title = "DISCOVERED DEVICES"
        if let image = UIImage(named: "network.png") {
            self.view.layer.contents = image.cgImage
            self.view.layer.contentsGravity = "resizeAspectFill"
        }
    #else
        setupTitle("ADD STORAGE")
    #endif
		serviceBrowser.delegate = self
		serviceBrowser.searchForServices(ofType: "_smb._tcp.", inDomain: "local")
    }
    
	func updateInterface () {
		for service in self.services {
            if let addresses = service.addresses {
                var ips: String = ""
                for address in addresses {
                    let ptr = (address as NSData).bytes.bindMemory(to: sockaddr_in.self, capacity: address.count)
                    var addr = ptr.pointee.sin_addr
                    let buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
                    let family = ptr.pointee.sin_family
                    if family == __uint8_t(AF_INET)
                    {
                        if let ipc:UnsafePointer<Int8> = inet_ntop(Int32(family), &addr, buf, __uint32_t(INET6_ADDRSTRLEN)) {
                            ips = String(cString: ipc)
                        }
                    }
                }
                if !hostInList(address: ips) {
                    hosts.append(ServiceHost(name: service.name, host: ips, port: Int32(service.port)))
                }
                if services.count == hosts.count {
                    let shares = Model.shared.allShares()
                    for share in shares {
                        if !hostInList(address: share.ip!) {
                            hosts.append(ServiceHost(name: share.ip!, host: share.ip!, port: share.port))
                        }
                    }
                }
                tableView.reloadData()
                service.stop()
            }
		}
	}
	
	func hostInList(address:String) -> Bool {
		for host in hosts {
			if host.host == address {
				return true
			}
		}
		return false
	}
	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return hosts.count
    }

    #if IOS
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "discovered devices"
    }
    #endif
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel!.text = hosts[(indexPath as NSIndexPath).row].name
        cell.textLabel?.font = UIFont.mainFont()
        cell.textLabel?.textColor = UIColor.black
        cell.textLabel?.textAlignment = .center
		return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: "showDevice", sender: hosts[indexPath.row])
	}
	
    @IBAction func addManual(_ sender: Any) {
    #if IOS
        let ask = HostInput.hostDialog(cancelHandler: {
        }, acceptHandler: { host, port in
            if let num = Int32(port) {
                let info = ServiceHost(name: "", host: host, port: num)
                self.performSegue(withIdentifier: "showDevice", sender: info)
            } else {
                self.showMessage("Invalid port number.", messageType: .error)
            }
        })
        ask?.show()
    #else
        let alert = UIAlertController(title: "Add host manually".uppercased(), message: "Enter IP address / Port".uppercased(), preferredStyle: .alert)
        var hostField:UITextField?
        var portField:UITextField?
        alert.addTextField(configurationHandler: { textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.textAlignment = .center
            textField.placeholder = "XXX.XXX.XXX.XXX".uppercased()
            hostField = textField
        })
        alert.addTextField(configurationHandler: { textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.textAlignment = .center
            textField.text = "445"
            textField.placeholder = "port".uppercased()
            portField = textField
        })
        alert.addAction(UIAlertAction(title: "ADD".uppercased(), style: .default, handler: { _ in
            if let hosttext = hostField?.text, let porttext = portField?.text, let num = Int32(porttext) {
                let info = ServiceHost(name: hosttext, host: hosttext, port: num)
                self.performSegue(withIdentifier: "showDevice", sender: info)
            } else {
                self.showMessage("Invalid port number.", messageType: .error)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel".uppercased(), style: .destructive, handler: { _ in
            self.goBack()
        }))
        present(alert, animated: true, completion: nil)
    #endif
    }
	
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDevice" {
			let controller = segue.destination as! DeviceController
			controller.target = sender as? ServiceHost
		}
    }
}

// MARK: - NSNetServiceDelegate

extension AddShareController:NetServiceDelegate {
	
	func netServiceDidResolveAddress(_ sender: NetService) {
		updateInterface()
        sender.startMonitoring()
	}
}

// MARK: - NSNetServiceBrowserDelegate

extension AddShareController:NetServiceBrowserDelegate {

	func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		services.append(service)
        service.delegate = self
        service.resolve(withTimeout:10)
	}
}


//
//  SearchInfoController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 20.02.17.
//  Copyright © 2017 Sergey Seitov. All rights reserved.
//

import UIKit
import SVProgressHUD

class SearchInfoController: UITableViewController {

	var node:Node?
	var results:[Any] = []
	
	private var imagesBaseURL:String?
	var searchFile:String!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupTitle("Search Info")
    #if IOS
        setupBackButton()
    #endif
		SVProgressHUD.show()
		searchFile = node!.name!
		
		TMDB.sharedInstance().get(kMovieDBConfiguration, parameters: nil, block: { result, err in
			SVProgressHUD.dismiss()
			if err == nil {
				if let config = result as? [String:Any] {
					if let imagesConfig = config["images"] as? [String:Any] {
						if let url = imagesConfig["base_url"] as? String {
							self.imagesBaseURL = "\(url)w185"
						} else {
							self.showMessage("Can not connect to TMDB", messageType: .error, messageHandler: {
								_ = self.navigationController?.popViewController(animated: true)
							})
						}
						return
					}
				}
				self.showMessage("Can not connect to TMDB", messageType: .error, messageHandler: {
					_ = self.navigationController?.popViewController(animated: true)
				})
			} else {
				self.showMessage("Can not connect to TMDB", messageType: .error, messageHandler: {
					_ = self.navigationController?.popViewController(animated: true)
				})
			}
		})
    }
    
#if IOS
    override func goBack() {
        dismiss(animated: true, completion: nil)
    }
#endif

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		search()
	}
	
	func search() {
		SVProgressHUD.show(withStatus: "Search...")
		TMDB.sharedInstance().get(kMovieDBSearchMovie, parameters: ["query": searchFile!], block: { responseObject, error in
			SVProgressHUD.dismiss()
			if error != nil {
				self.showMessage("Can not find info for \"\(self.searchFile!)\"", messageType: .information)
			} else {
				if let response = responseObject as? [String:Any] {
					if let results = response["results"] as? [Any] {
						if results.count > 0 {
							self.results = results
							self.tableView.reloadData()
						} else {
							self.showMessage("No results found for \"\(self.searchFile!)\"", messageType: .information)
						}
					}
				}
			}
		})
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return section == 0 ? "search" : "found results"
	}
	
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : results.count
    }
    
#if IOS
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
#endif
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    #if TV
        return indexPath.section == 0 ? 66 : 240
    #else
        return indexPath.section == 0 ? 44 : 120
    #endif
	}
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "searchField") as! SearchCell
			cell.field.text = searchFile
			cell.accessoryType = .none
        #if IOS
            cell.delegate = self
        #endif
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "searchResult", for: indexPath) as! SearchResultCell
			cell.imagesBaseURL = imagesBaseURL
			cell.movie = results[indexPath.row] as? [String:Any]
			return cell
		}
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
        #if TV
			var nameField:UITextField?
			let alert = UIAlertController(title: "Search Info", message: "Input title of movie:", preferredStyle: .alert)
			alert.addTextField(configurationHandler: { textField in
				textField.textAlignment = .center
				textField.text = self.searchFile
				nameField = textField
			})
			alert.addAction(UIAlertAction(title: "Search", style: .destructive, handler: { _ in
				self.searchFile = nameField?.text
				self.tableView.reloadData()
				self.search()
			}))
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			present(alert, animated: true, completion: nil)
        #endif
		} else {
			if let movie = results[indexPath.row] as? [String:Any] {
				performSegue(withIdentifier: "editInfo", sender: movie)
			}
		}
	}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "editInfo" {
			let next = segue.destination as! InfoViewController
			next.imageBaseURL = imagesBaseURL
			next.info = sender as? [String:Any]
			next.node = node
		}
    }
}

#if IOS
    extension SearchInfoController : SearchCellDelegate {
        func fieldDidChanged(_ text:String?) {
            if text != nil {
                searchFile = text
                tableView.reloadData()
                search()
            }
        }
    }
#endif

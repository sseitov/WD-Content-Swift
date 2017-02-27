//
//  InfoViewController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 21.02.17.
//  Copyright © 2017 Sergey Seitov. All rights reserved.
//

import UIKit
import SVProgressHUD

class InfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoTable: UITableView!
    @IBOutlet weak var castView: UITextView!
    @IBOutlet weak var overviewView: UITextView!
    @IBOutlet weak var castConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
	
	var info:[String:Any]?
	var imageBaseURL:String?
	var node:Node?
	var metainfo:MetaInfo?
	
	private var movieInfo:[String:Any]?
	private var credits:[String:Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
		setupTitle("Movie Info")
    #if IOS
        setupBackButton()
        if IS_PAD() {
            imageWidthConstraint.constant = 200
            imageHeightConstraint.constant = 240
            tableHeightConstraint.constant = 240
        }
    #endif
		castConstraint.constant = 0
		if info == nil && metainfo != nil {
            let btn = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(self.clearInfo))
        #if IOS
            btn.tintColor = UIColor.white
        #endif
			navigationItem.rightBarButtonItem = btn
		}
		
		if info != nil, let uid = info!["id"] as? Int {
            let btn = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.saveInfo))
        #if IOS
            btn.tintColor = UIColor.white
        #endif
			navigationItem.rightBarButtonItem = btn
			SVProgressHUD.show(withStatus: "Load Info...")
			TMDB.sharedInstance().get(kMovieDBMovie, parameters: ["id" : "\(uid)"], block: { responseObject, error in
				if let movieInfo = responseObject as? [String:Any] {
					self.movieInfo = movieInfo
					TMDB.sharedInstance().get(kMovieDBMovieCredits, parameters: ["id" : "\(uid)"], block: { response, error in
						if let credits = response as? [String:Any] {
							self.credits = credits
						}
						self.showInfo()
						SVProgressHUD.dismiss()
					})
				} else {
					self.showInfo()
					SVProgressHUD.dismiss()
				}
			})
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		showInfo()
	}
    
#if TV
	override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
		if presses.first != nil && presses.first!.type == .menu {
			if metainfo != nil {
				dismiss(animated: true, completion: nil)
			} else {
				_ = navigationController?.popViewController(animated: true)
			}
		}
	}
#else
    override func goBack() {
        if metainfo != nil {
            dismiss(animated: true, completion: nil)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
#endif
    
	func showInfo() {
		if metainfo != nil {
			setupTitle(metainfo!.title!)
			if metainfo!.poster != nil, let url = URL(string: metainfo!.poster!) {
				imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
			} else {
				imageView.image = UIImage(named: "movie")
			}
			castView.text = metainfo!.cast
			overviewView.text = metainfo!.overview
		} else {
			setupTitle(info!["title"] as! String)
			if let url = URL(string: posterPath()) {
				imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
			} else {
				imageView.image = UIImage(named: "movie")
			}
			castView.text = cast()
			overviewView.text = info!["overview"] as? String
		}
		infoTable.reloadData()
		if castView.text != nil {
        #if IOS
            let offset:CGFloat = 20
        #else
            let offset:CGFloat = 40
        #endif
			let castHeight = castView.text!.heightWithConstrainedWidth(width: castView.frame.width, font: castView.font!) + offset
			let overviewHeight = overviewView.text!.heightWithConstrainedWidth(width: overviewView.frame.width, font: overviewView.font!) + offset
			let height = self.view.frame.height - castView.frame.origin.y - overviewHeight - offset*2
			castConstraint.constant = castHeight > height ? height : castHeight
		}
	}
	
	func clearInfo() {
        SVProgressHUD.show(withStatus: "Clear...")
        Model.shared.clearInfo(metainfo!, result: { error in
            SVProgressHUD.dismiss()
            if error != nil {
                self.showMessage("Cloud clear error: \(error!)", messageType: .information, messageHandler: {
                    self.dismiss(animated: true, completion: nil)
                })
            } else {
                NotificationCenter.default.post(name: refreshNodeNotification, object: self.node)
                self.dismiss(animated: true, completion: nil)
            }
        })
	}
	
	func saveInfo() {
        SVProgressHUD.show(withStatus: "Save...")
        Model.shared.setInfoForNode(node!,
                                    title: title(),
                                    overview: overview(),
                                    release_date: release_date(),
                                    poster: posterPath(),
                                    runtime: runtime(),
                                    rating: rating(),
                                    genre: genres(),
                                    cast: cast(),
                                    director: director(),
                                    result:
            { error in
                SVProgressHUD.dismiss()
                if error != nil {
                    self.showMessage("Cloud save error: \(error!)", messageType: .information, messageHandler: {
                        self.dismiss(animated: true, completion: nil)
                    })
                } else {
                    NotificationCenter.default.post(name: refreshNodeNotification, object: self.node)
                    self.dismiss(animated: true, completion: nil)
                }
        })
	}
    
    private func title() -> String {
        if let val = info!["title"] as? String {
            return val
        } else {
            return ""
        }
    }
    
    private func overview() -> String {
        if let val = info!["overview"] as? String {
            return val
        } else {
            return ""
        }
    }
    
    private func release_date() -> String {
        if let val = info!["release_date"] as? String {
            return val
        } else {
            return ""
        }
    }

	private func posterPath() -> String {
		if let posterPath = info!["poster_path"] as? String {
			return "\(imageBaseURL!)\(posterPath)"
		} else {
			return "";
		}
	}
	
	private func runtime() -> String {
		if movieInfo != nil, let runtime = movieInfo!["runtime"] as? Int {
			return "\(runtime)"
		} else {
			return ""
		}
	}
	
	private func genres() -> String {
		if movieInfo != nil, let genresArr = movieInfo!["genres"] as? [Any] {
			var genres:[String] = []
			for item in genresArr {
				if let genreItem = item as? [String:Any], let genre = genreItem["name"] as? String {
					genres.append(genre)
				}
			}
			return genres.joined(separator: ", ")
		} else {
			return ""
		}
	}
	
	private func rating() -> String {
		if movieInfo != nil, let popularity = movieInfo!["vote_average"] as? Double {
			return "\(popularity)"
		} else {
			return ""
		}
	}

	private func cast() -> String {
		if credits != nil, let castArr = credits!["cast"] as? [Any] {
			var cast:[String] = []
			for item in castArr {
				if let casting = item as? [String:Any], let name = casting["name"] as? String {
					cast.append(name)
				}
			}
			return cast.joined(separator: ", ")
		} else {
			return ""
		}
	}
	
	private func director() -> String {
		if credits != nil, let crewArr =  credits!["crew"] as? [Any] {
			var director:[String] = []
			for item in crewArr {
				if let crew = item as? [String:Any], let job = crew["job"] as? String, job == "Director", let name = crew["name"] as? String {
					director.append(name)
				}
			}
			return director.joined(separator: ", ")
		} else {
			return ""
		}
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 5
	}
    
#if IOS
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IS_PAD() ? 44 : 30
    }
#endif
    
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    #if TV
		let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
    #else
        var cell:UITableViewCell!
        if IS_PAD() {
            cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        }
    #endif
		switch indexPath.row {
		case 0:
			cell.textLabel?.text = "Director"
			cell.detailTextLabel?.text = metainfo != nil ? metainfo!.director : director()
		case 1:
			cell.textLabel?.text = "Release Date"
            if let text = metainfo != nil ? metainfo!.release_date : info!["release_date"] as? String {
                cell.detailTextLabel?.text = Model.releaseDate(text)
            } else {
                cell.detailTextLabel?.text = ""
            }
		case 2:
			cell.textLabel?.text = "Runtime"
			if let runtime = metainfo != nil ? metainfo!.runtime : runtime() {
				cell.detailTextLabel?.text = "\(runtime) min"
			} else {
				cell.detailTextLabel?.text = ""
			}
		case 3:
			cell.textLabel?.text = "Genres"
			cell.detailTextLabel?.text = metainfo != nil ? metainfo!.genre : genres()
		case 4:
			cell.textLabel?.text = "Rating"
			cell.detailTextLabel?.text = metainfo != nil ? metainfo!.rating : rating()
		default:
			break
		}
        cell.textLabel?.textColor = UIColor.mainColor()
    #if TV
        cell.textLabel?.font = UIFont.condensedFont()
        cell.detailTextLabel?.font = UIFont.mainFont()
    #else
        if IS_PAD() {
            cell.textLabel?.font = UIFont.condensedFont(17)
            cell.detailTextLabel?.font = UIFont.mainFont(15)
        } else {
            cell.textLabel?.font = UIFont.condensedFont(13)
            cell.detailTextLabel?.font = UIFont.mainFont(10)
        }
    #endif
		return cell
	}
}

extension String {
	
	func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
		
		return boundingBox.height
	}
}


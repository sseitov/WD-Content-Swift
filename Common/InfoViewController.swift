//
//  InfoViewController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 21.02.17.
//  Copyright © 2017 Sergey Seitov. All rights reserved.
//

import UIKit
import SVProgressHUD

class InfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SearchInfoDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoTable: UITableView!
    @IBOutlet weak var castView: UITextView!
    @IBOutlet weak var overviewView: UITextView!
    @IBOutlet weak var castConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var findButton: UIButton!
    
	var node:Node?
	var metainfo:MetaInfo?

    private var imageBaseURL:String?
    private var info:[String:Any]?
	
	private var movieInfo:[String:Any]?
	private var credits:[String:Any]?
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTitle("Movie Info")
        findButton.setupBorder(UIColor.mainColor(), radius: 5)
        setupBackButton()
        if IS_PAD() {
            imageWidthConstraint.constant = 200
            imageHeightConstraint.constant = 240
            tableHeightConstraint.constant = 300
        }
        
        castConstraint.constant = 0
        metainfo = node!.info
		if metainfo != nil {
            let btn = UIBarButtonItem(title: "CLEAR INFO", style: .plain, target: self, action: #selector(self.clearInfo))
            #if IOS
                btn.tintColor = UIColor.white
            #endif
			navigationItem.rightBarButtonItem = btn
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        if info != nil, let uid = info!["id"] as? Int {
            let btn = UIBarButtonItem(title: "SAVE INFO", style: .plain, target: self, action: #selector(self.saveInfo))
            btn.tintColor = UIColor.white
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
        } else {
            showInfo()
        }
	}

    override func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
	func showInfo() {
        setupTitle(title(), color: UIColor.black)
        if let url = URL(string: posterPath()) {
        #if TV
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
        #else
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "file"))
        #endif
        } else {
        #if TV
            imageView.image = UIImage(named: "movie")
        #else
            imageView.image = UIImage(named: "file")
        #endif
        }
        castView.text = cast()
        overviewView.text = overview()
		infoTable.reloadData()
		if castView.text != nil {
            let offset:CGFloat = 20
			let castHeight = castView.text!.heightWithConstrainedWidth(width: castView.frame.width, font: castView.font!) + offset
			let overviewHeight = overviewView.text!.heightWithConstrainedWidth(width: overviewView.frame.width, font: overviewView.font!) + offset
			var height = self.view.frame.height - castView.frame.origin.y - overviewHeight - offset*2
            if height < 120 {
                height = 120
            }
			castConstraint.constant = castHeight > height ? height : castHeight
		}
	}
	
	@objc func clearInfo() {
        SVProgressHUD.show(withStatus: "Clear...")
        Model.shared.clearInfo(metainfo!, result: { error in
            SVProgressHUD.dismiss()
            if error != nil {
                self.showMessage("Cloud clear error: \(error!.localizedDescription)", messageType: .information, messageHandler: {
                    self.dismiss(animated: true, completion: nil)
                })
            } else {
                NotificationCenter.default.post(name: refreshNodeNotification, object: self.node)
                self.dismiss(animated: true, completion: nil)
            }
        })
	}
	
	@objc func saveInfo() {
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
        if metainfo != nil {
            return metainfo!.title!
        } else if info != nil, let val = info!["title"] as? String {
            return val
        } else {
            return node!.dislayName()
        }
    }
    
    private func overview() -> String {
        if metainfo != nil {
            return metainfo!.overview!
        } else if info != nil, let val = info!["overview"] as? String {
            return val
        } else {
            return ""
        }
    }
    
    private func release_date() -> String {
        if metainfo != nil {
            return metainfo!.release_date!
        } else if info != nil, let val = info!["release_date"] as? String {
            return Model.releaseDate(val)
        } else {
            return ""
        }
    }

	private func posterPath() -> String {
        if metainfo != nil {
            return metainfo!.poster!
        } else if info != nil, let posterPath = info!["poster_path"] as? String {
			return "\(imageBaseURL!)\(posterPath)"
		} else {
			return "";
		}
	}
	
	private func runtime() -> String {
        if metainfo != nil {
            return "\(metainfo!.runtime!) min"
        } else if movieInfo != nil, let runtime = movieInfo!["runtime"] as? Int {
			return "\(runtime) min"
		} else {
			return ""
		}
	}
	
	private func genres() -> String {
        if metainfo != nil {
            return metainfo!.genre!
        } else if movieInfo != nil, let genresArr = movieInfo!["genres"] as? [Any] {
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
        if metainfo != nil {
            return metainfo!.rating!
        } else if movieInfo != nil, let popularity = movieInfo!["vote_average"] as? Double {
			return "\(popularity)"
		} else {
			return ""
		}
	}

	private func cast() -> String {
        if metainfo != nil {
            return metainfo!.cast!
        } else if credits != nil, let castArr = credits!["cast"] as? [Any] {
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
        if metainfo != nil {
            return metainfo!.director!
        } else if credits != nil, let crewArr =  credits!["crew"] as? [Any] {
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return IS_PAD() ? 44 : 30
    }
    
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell!
        if IS_PAD() {
            cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        }
        cell.backgroundColor = UIColor.clear
        cell.detailTextLabel?.textColor = UIColor.black
		switch indexPath.row {
		case 0:
			cell.textLabel?.text = "DIRECTOR"
			cell.detailTextLabel?.text = director()
		case 1:
			cell.textLabel?.text = "RELEASE DATE"
            cell.detailTextLabel?.text = release_date()
		case 2:
			cell.textLabel?.text = "RUNTIME"
            cell.detailTextLabel?.text = runtime()
		case 3:
			cell.textLabel?.text = "GENRES"
			cell.detailTextLabel?.text = genres()
		case 4:
			cell.textLabel?.text = "RATING"
			cell.detailTextLabel?.text = rating()
		default:
			break
		}
        cell.textLabel?.textColor = UIColor.mainColor()
        if IS_PAD() {
            cell.textLabel?.font = UIFont.condensedFont(17)
            cell.detailTextLabel?.font = UIFont.mainFont(15)
        } else {
            cell.textLabel?.font = UIFont.condensedFont(13)
            cell.detailTextLabel?.font = UIFont.mainFont(10)
        }
		return cell
	}
    
    
    // MARK: - Navigation
    
    @IBAction func play(_ sender: Any) {
        if info != nil {
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
                    if error == nil {
                        NotificationCenter.default.post(name: refreshNodeNotification, object: self.node)
                    }
                    self.performSegue(withIdentifier: "play", sender: nil)
            })
        } else {
            self.performSegue(withIdentifier: "play", sender: nil)
        }
    }
    
    func didFoundInfo(_ info:[String:Any], baseURL:String) {
        imageBaseURL = baseURL
        self.info = info
        showInfo()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchInfo" {
            let next = segue.destination as! SearchInfoController
            next.node = node
            next.delegate = self
        } else if segue.identifier == "play" {
            let next = segue.destination as! VideoPlayer
            next.nodes = [node!]
        }
    }

}

extension String {
	
	func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
		let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
		let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
		
		return boundingBox.height
	}
}


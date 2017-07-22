//
//  FolderController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 22.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class FolderController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, SearchInfoDelegate {

    var parentNode:Node?
    var nodes:[Node] = []

    @IBOutlet weak var cover: UIImageView!
    @IBOutlet weak var nodesTable: UITableView!
    @IBOutlet weak var infoTable: UITableView!
    @IBOutlet weak var overviewView: UITextView!
  
    private var selectedNode:Node?
    private var selectedInfo:MetaInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = self.view.setGradientBackground(top: UIColor.mainColor(), bottom: UIColor.gradientColor(), size: self.view.frame.size)
        
        let backTap = UITapGestureRecognizer(target: self, action: #selector(self.goBack))
        backTap.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        self.view.addGestureRecognizer(backTap)
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.pressLongTap(tap:)))
        longTap.delegate = self
        nodesTable?.addGestureRecognizer(longTap)

        nodesTable.remembersLastFocusedIndexPath = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshNode(notyfy:)),
                                               name: refreshNodeNotification,
                                               object: nil)

        refresh()
    }

    override func goBack() {
        if parentNode?.parent != nil {
            parentNode = parentNode!.parent
            refresh()
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nodesTable.reloadData()
    }
    
    func refresh() {
        self.title = parentNode?.dislayName().uppercased()
        
        SVProgressHUD.show(withStatus: "Refresh...")
        self.nodes = []
        self.cover.image = nil
        self.nodesTable.reloadData()
        
        DispatchQueue.global().async {
            self.nodes = Model.shared.nodes(byRoot: self.parentNode!)
            for node in self.nodes {
                node.parent = self.parentNode
                node.share = self.parentNode!.share
                node.info = Model.shared.getInfoForNode(node)
            }
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.nodesTable.reloadData()
                if self.nodes.count > 0 {
                    self.selectedNode = self.nodes[0]
                    self.selectedInfo = Model.shared.getInfoForNode(self.selectedNode!)
                } else {
                    self.selectedNode = nil
                    self.selectedInfo = nil
                }
                self.updateInfo()
            }
        }
    }
    
    func refreshNode(notyfy:Notification) {
        if let node = notyfy.object as? Node, node.parent == parentNode {
            if let index = nodes.index(of: node) {
                nodesTable.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                if node == selectedNode {
                    selectedInfo = Model.shared.getInfoForNode(node)
                    updateInfo()
                }
            }
        }
    }

    func pressLongTap(tap:UILongPressGestureRecognizer) {
        if tap.state == .began {
            if selectedNode != nil {
                if !selectedNode!.directory {
                    self.performSegue(withIdentifier: "info", sender: selectedNode)
                }
            }
        }
    }

    // MARK: UITableView delegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == nodesTable {
            return nodes.count
        } else {
            return selectedInfo != nil ? 5 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if tableView == nodesTable {
            let node = nodes[indexPath.row]
            cell.textLabel?.numberOfLines = 0
            if node.directory {
                cell.textLabel?.text = node.dislayName().uppercased()
                cell.imageView?.image = UIImage(named: "folder")
                cell.detailTextLabel?.text = ""
            } else {
                if let info = Model.shared.getInfoForNode(node) {
                    if info.title != nil {
                        cell.textLabel?.text = info.title
                    } else {
                        cell.textLabel?.text = node.dislayName()
                    }
                    if info.release_date != nil {
                        cell.detailTextLabel?.text = Model.year(info.release_date!)
                    } else {
                        cell.detailTextLabel?.text = ""
                    }
                    if info.wasViewed {
                        cell.imageView?.image = UIImage(named: "checked")
                    } else {
                        cell.imageView?.image = UIImage(named: "unchecked")
                    }
                } else {
                    cell.textLabel?.text = node.dislayName()
                    cell.imageView?.image = nil
                    cell.detailTextLabel?.text = ""
                    Model.shared.updateInfoForNode(node)
                }
            }
        } else {
            cell.textLabel?.textColor = UIColor.white
            cell.detailTextLabel?.numberOfLines = 0
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "DIRECTOR"
                cell.detailTextLabel?.text = selectedInfo?.director
            case 1:
                cell.textLabel?.text = "RELEASE"
                cell.detailTextLabel?.text = selectedInfo?.release_date
            case 2:
                cell.textLabel?.text = "RUNTIME"
                cell.detailTextLabel?.text = selectedInfo?.runtime
            case 3:
                cell.textLabel?.text = "GENRES"
                cell.detailTextLabel?.text = selectedInfo?.genre
            case 4:
                cell.textLabel?.text = "RATING"
                cell.detailTextLabel?.text = selectedInfo?.rating
            default:
                break
            }
        }
        return cell
    }

    private func posterURL(_ info:MetaInfo) -> URL? {
        if info.poster != nil {
            return URL(string: info.poster!)
        } else {
            return nil;
        }
    }

    private func updateInfo() {
        if selectedNode != nil {
            if self.selectedNode!.directory {
                self.cover.image = UIImage(named: "folderCover")
                overviewView.text = ""
            } else {
                if selectedInfo != nil {
                    if let url = self.posterURL(selectedInfo!) {
                        self.cover.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
                    } else {
                        self.cover.image = UIImage(named: "movie")
                    }
                    overviewView.text = selectedInfo!.overview
                } else {
                    self.cover.image = nil
                    overviewView.text = ""
                }
            }
        } else {
            self.cover.image = nil
            overviewView.text = ""
        }
        infoTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        if tableView == nodesTable {
            if let index = context.nextFocusedIndexPath {
                selectedNode = nodes[index.row]
                selectedInfo = Model.shared.getInfoForNode(selectedNode!)
            } else {
                selectedNode = nil
                selectedInfo = nil
            }
            updateInfo()
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == nodesTable {
            tableView.deselectRow(at: indexPath, animated: false)
            let node = nodes[indexPath.row]
            if node.directory {
                parentNode = node
                if parentNode?.parent != nil {
                    parentNode?.parent!.selectedIndexPath = indexPath
                }
                refresh()
            } else {
                parentNode?.selectedIndexPath = indexPath
                self.performSegue(withIdentifier: "play", sender: node)
            }
        }
    }

    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        if tableView == nodesTable {
            if let index = parentNode?.selectedIndexPath {
                return index
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "play" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! VideoPlayer
            next.node = sender as? Node
        } else if segue.identifier == "info" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! SearchInfoController
            next.node = sender as? Node
            next.delegate = self
        }
    }
    
    // MARK: - Update Info
    
    func didFoundInfo(_ info:[String:Any], baseURL:String) {
        dismiss(animated: true, completion: {
            if let node = self.selectedNode {
                SVProgressHUD.show(withStatus: "Update...")
                if node.info != nil {
                    Model.shared.clearInfo(node.info!, result: { error in
                        if error != nil {
                            SVProgressHUD.dismiss()
                            self.showMessage(error!.localizedDescription, messageType: .error)
                        } else {
                            self.saveInfoForNode(node, info: info, baseURL: baseURL, result: { saveError in
                                SVProgressHUD.dismiss()
                                if saveError != nil {
                                    self.showMessage(saveError!.localizedDescription, messageType: .error)
                                } else {
                                    self.selectedInfo = Model.shared.getInfoForNode(node)
                                    self.updateInfo()
                                    self.nodesTable.reloadData()
                                }
                            })
                        }
                    })
                } else {
                    self.saveInfoForNode(node, info: info, baseURL: baseURL, result: { saveError in
                        SVProgressHUD.dismiss()
                        if saveError != nil {
                            self.showMessage(saveError!.localizedDescription, messageType: .error)
                        } else {
                            self.selectedInfo = Model.shared.getInfoForNode(node)
                            self.updateInfo()
                            self.nodesTable.reloadData()
                        }
                    })
                }
            }
        })
    }
    
    private func saveInfoForNode(_ node:Node, info:[String:Any], baseURL:String, result: @escaping(Error?) -> ()) {
        if let uid = info["id"] as? Int {
            TMDB.sharedInstance().get(kMovieDBMovie, parameters: ["id" : "\(uid)"], block: { responseObject, error in
                if let movieInfo = responseObject as? [String:Any] {
                    TMDB.sharedInstance().get(kMovieDBMovieCredits, parameters: ["id" : "\(uid)"], block: { response, error in
                        if let credits = response as? [String:Any] {
                            Model.shared.setInfoForNode(node,
                                                        title: self.name(node, info:info),
                                                        overview: self.overview(info),
                                                        release_date: self.release_date(info),
                                                        poster: self.posterPath(info, baseURL: baseURL),
                                                        runtime: self.runtime(movieInfo),
                                                        rating: self.rating(movieInfo),
                                                        genre: self.genres(movieInfo),
                                                        cast: self.cast(credits),
                                                        director: self.director(credits),
                                                        result:
                                { error in
                                    result(error)
                            })
                        } else {
                            Model.shared.setInfoForNode(node,
                                                        title: self.name(node, info:info),
                                                        overview: self.overview(info),
                                                        release_date: self.release_date(info),
                                                        poster: self.posterPath(info, baseURL: baseURL),
                                                        runtime: self.runtime(movieInfo),
                                                        rating: self.rating(movieInfo),
                                                        genre: self.genres(movieInfo),
                                                        cast: self.cast(nil),
                                                        director: self.director(nil),
                                                        result:
                                { error in
                                    result(error)
                            })
                        }
                    })
                } else {
                    Model.shared.setInfoForNode(node,
                                                title: self.name(node, info:info),
                                                overview: self.overview(info),
                                                release_date: self.release_date(info),
                                                poster: self.posterPath(info, baseURL: baseURL),
                                                runtime: self.runtime(nil),
                                                rating: self.rating(nil),
                                                genre: self.genres(nil),
                                                cast: self.cast(nil),
                                                director: self.director(nil),
                                                result:
                        { error in
                            result(error)
                    })
                }
            })
        }
    }

    private func name(_ node:Node, info:[String:Any]) -> String {
        if let val = info["title"] as? String {
            return val
        } else {
            return node.dislayName()
        }
    }
    
    private func overview(_ info:[String:Any]) -> String {
        if let val = info["overview"] as? String {
            return val
        } else {
            return ""
        }
    }
    
    private func release_date(_ info:[String:Any]) -> String {
        if let val = info["release_date"] as? String {
            return Model.releaseDate(val)
        } else {
            return ""
        }
    }
    
    private func posterPath(_ info:[String:Any], baseURL:String) -> String {
        if let posterPath = info["poster_path"] as? String {
            return "\(baseURL)\(posterPath)"
        } else {
            return "";
        }
    }
    
    private func runtime(_ movieInfo:[String:Any]?) -> String {
        if movieInfo != nil, let runtime = movieInfo!["runtime"] as? Int {
            return "\(runtime) min"
        } else {
            return ""
        }
    }
    
    private func genres(_ movieInfo:[String:Any]?) -> String {
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
    
    private func rating(_ movieInfo:[String:Any]?) -> String {
        if movieInfo != nil, let popularity = movieInfo!["vote_average"] as? Double {
            return "\(popularity)"
        } else {
            return ""
        }
    }
    
    private func cast(_ credits:[String:Any]?) -> String {
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

    private func director(_ credits:[String:Any]?) -> String {
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

}

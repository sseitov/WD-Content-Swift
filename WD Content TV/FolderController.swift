//
//  FolderController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 22.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class InfoCell: UITableViewCell {
    @IBOutlet weak var infoTitle: UILabel!
    @IBOutlet weak var infoText: UITextView!
}

class CoverCell: UITableViewCell {
    @IBOutlet weak var cover: UIImageView!
}

class FolderController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, SearchInfoDelegate, NodeCellDelegate {

    var parentNode:Node?
    var nodes:[Node] = []

    @IBOutlet weak var infoTable: UITableView!
    @IBOutlet weak var nodesTable: UITableView!
    @IBOutlet weak var coverTable: UITableView!
    
    private var focusedNode:Node?
    
    @IBOutlet weak var nodesBottom: NSLayoutConstraint!
    @IBOutlet weak var coverBottom: NSLayoutConstraint!
    @IBOutlet weak var infoBottom: NSLayoutConstraint!
    @IBOutlet weak var infoTop: NSLayoutConstraint!
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = UIImage(named: "background.jpg") {
            self.view.layer.contents = image.cgImage
            self.view.layer.contentsGravity = "resizeAspectFill"
        }

        let backTap = UITapGestureRecognizer(target: self, action: #selector(self.goBack))
        backTap.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        self.view.addGestureRecognizer(backTap)
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.pressLongTap(tap:)))
        longTap.delegate = self
        nodesTable?.addGestureRecognizer(longTap)
        
        nodesTable.remembersLastFocusedIndexPath = false
        
        infoBottom.constant = 60
        coverBottom.constant = 60
        nodesBottom.constant = 60
        infoTop.constant = -60
        
        refresh()
    }
    
    override func goBack() {
        focusedNode = nil
        if parentNode?.parent != nil {
            parentNode = parentNode!.parent
            refresh()
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func pressLongTap(tap:UILongPressGestureRecognizer) {
        if tap.state == .began {
            if focusedNode != nil {
                if focusedNode!.directory {
                    SVProgressHUD.show()
                    DispatchQueue.global().async {
                        let nodes = Model.shared.nodes(byRoot: self.focusedNode!)
                        for node in nodes {
                            node.parent = self.parentNode
                            node.share = self.parentNode!.share
                            node.info = Model.shared.getInfoForNode(node)
                        }
                        DispatchQueue.main.async {
                            SVProgressHUD.dismiss()
                            self.performSegue(withIdentifier: "play", sender: nodes)
                        }
                    }
                } else {
                    self.performSegue(withIdentifier: "info", sender: focusedNode)
                }
            }
        }
    }
    
    func refresh() {
        SVProgressHUD.show(withStatus: "Refresh...")
        DispatchQueue.global().async {
            let nodes = Model.shared.nodes(byRoot: self.parentNode!)
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                if nodes.count > 0 {
                    self.nodes = nodes
                    for node in self.nodes {
                        node.parent = self.parentNode
                        node.share = self.parentNode!.share
                        node.info = Model.shared.getInfoForNode(node)
                    }
                    self.nodesTable.reloadData()
                    if self.focusedNode == nil {
                        if self.parentNode?.selectedIndexPath == nil && self.nodes.count > 0 {
                            self.focusedNode = self.nodes[0]
                        } else {
                            self.focusedNode = self.nodes[self.parentNode!.selectedIndexPath!.row]
                        }
                    }
                    self.infoTable.reloadData()
                    self.coverTable.reloadData()
                } else {
                    self.nodes = []
                    self.showMessage("Folder not contains movies.".uppercased(), messageType: .information, messageHandler: {
                        self.goBack()
                    })
                }
            }
        }
    }
    
    func reloadInfoFor(node:Node?) {
        if node == focusedNode {
            infoTable.reloadData()
            coverTable.reloadData()
        }
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == nodesTable {
            return nodes.count
        } else {
            if focusedNode != nil && !focusedNode!.directory && focusedNode!.info != nil {
                return 3
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == nodesTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeCell
            cell.node = nodes[indexPath.row]
            return cell
        } else if tableView == coverTable {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "director", for: indexPath) as! InfoCell
                cell.infoTitle.text = "DIRECTOR"
                cell.infoText?.text = focusedNode?.info?.director
                cell.infoText.contentOffset = CGPoint.zero
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cover", for: indexPath) as! CoverCell
                if focusedNode!.info!.poster != nil, let url = URL(string: focusedNode!.info!.poster!) {
                    cell.cover.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
                } else {
                    cell.cover.image = nil
                }
                return cell
            default:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "RUNTIME"
                cell.textLabel?.textColor = UIColor.black
                cell.textLabel?.alpha = 0.5
                cell.detailTextLabel?.text = focusedNode?.info?.runtime
                cell.detailTextLabel?.textColor = UIColor.black
                cell.detailTextLabel?.alpha = 0.7
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "info", for: indexPath) as! InfoCell
            switch indexPath.row {
            case 0:
                cell.infoTitle.text = "GENRES"
                cell.infoText?.text = focusedNode?.info?.genre
                cell.infoText.contentOffset = CGPoint.zero
            case 1:
                cell.infoTitle.text = "CAST"
                cell.infoText?.text = focusedNode?.info?.cast
                cell.infoText.contentOffset = CGPoint.zero
            default:
                cell.infoTitle.text = "OVERVIEW"
                cell.infoText?.text = focusedNode?.info?.overview
                cell.infoText.contentOffset = CGPoint.zero
            }
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == nodesTable {
            let node = nodes[indexPath.row]
            if node.directory {
                parentNode = node
                if parentNode?.parent != nil {
                    parentNode?.parent!.selectedIndexPath = indexPath
                }
                focusedNode = nil
                refresh()
            } else {
                parentNode?.selectedIndexPath = indexPath
                self.performSegue(withIdentifier: "play", sender: [node])
            }
        }
    }
    
    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        if tableView == nodesTable {
            if focusedNode != nil {
                if let index = nodes.index(of: focusedNode!) {
                    return IndexPath(row: index, section: 0)
                } else {
                    return IndexPath(row: 0, section: 0)
                }
            } else {
                if let index = self.parentNode?.selectedIndexPath {
                    return index
                } else {
                    return IndexPath(row: 0, section: 0)
                }
            }
        } else {
            return IndexPath(row: 0, section: 0)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        if tableView == nodesTable {
            if let index = context.nextFocusedIndexPath {
                focusedNode = nodes[index.row]
            } else {
                focusedNode = nil
            }
            infoTable.reloadData()
            coverTable.reloadData()
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == infoTable {
            switch indexPath.row {
            case 0:
                return 140
            case 1:
                return 180
            default:
                return infoTable.frame.size.height - 240
            }
        } else if tableView == coverTable {
            switch indexPath.row {
            case 0:
                return 100
            case 1:
                return coverTable.frame.size.height - 260
            default:
                return 60
            }
        } else {
            return 120
        }
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "play" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! VideoPlayer
            if let nodes = sender as? [Node] {
                next.nodes = nodes
            }
        } else if segue.identifier == "info" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! SearchInfoController
            next.node = sender as? Node
            next.delegate = self
        }
    }

    // MARK: - SearchDelegate
    
    func didFoundInfo(_ info:[String:Any], baseURL:String) {
        dismiss(animated: true, completion: {
            if let node = self.focusedNode {
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

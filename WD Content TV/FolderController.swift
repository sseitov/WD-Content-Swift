//
//  FolderController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 22.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class FolderController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, SearchInfoDelegate, NodeCellDelegate {

    var parentNode:Node?
    var nodes:[Node] = []

    @IBOutlet weak var nodesTable: UITableView!
    @IBOutlet weak var coverView: CoverView!
    @IBOutlet weak var infoView: InfoView!
    
    private var focusedNode:Node?
    
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
        
        nodesTable.remembersLastFocusedIndexPath = true
        
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
        self.nodes = []
        self.infoView.node = nil
        self.coverView.node = nil
        self.nodesTable.reloadData()
        
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
                    if self.parentNode?.selectedIndexPath  == nil && self.nodes.count > 0 {
                        self.focusedNode = self.nodes[0]
                    }
                } else {
                    self.showMessage("Folder not contains movies.".uppercased(), messageType: .information, messageHandler: {
                        self.goBack()
                    })
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeCell
        cell.node = nodes[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = nodes[indexPath.row]
        if node.directory {
            parentNode = node
            if parentNode?.parent != nil {
                parentNode?.parent!.selectedIndexPath = indexPath
            }
            refresh()
        } else {
            parentNode?.selectedIndexPath = indexPath
            self.performSegue(withIdentifier: "play", sender: [node])
        }
    }
    
    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        if let index = parentNode?.selectedIndexPath {
            return index
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        if let index = context.nextFocusedIndexPath {
            focusedNode = nodes[index.row]
        } else {
            focusedNode = nil
        }
        return true
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
    
    // MARK: - NodeCellDelegate
    
    func didUpdateInfo(_ node:Node) {
        self.infoView.node = node
        self.coverView.node = node
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

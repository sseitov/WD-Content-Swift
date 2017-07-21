//
//  ContentController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 24.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class ContentController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var parentNode:Node?
    var nodes:[Node] = []
    
    private var gradient:CAGradientLayer?
 
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func gradientSize() -> CGSize {
        let max = self.view.frame.size.width > self.view.frame.size.height ? self.view.frame.size.width : self.view.frame.size.height
        return CGSize(width: max, height: max)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.backgroundView = UIView()
        gradient = self.collectionView.backgroundView?.setGradientBackground(top: UIColor.mainColor(), bottom: UIColor.gradientColor(), size: gradientSize())
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshNotify),
                                               name: refreshNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshNode(notyfy:)),
                                               name: refreshNodeNotification,
                                               object: nil)
        refresh()
    }
    
    func refreshNotify() {
        collectionView.reloadData()
    }
    
    func refreshNode(notyfy:Notification) {
        if let node = notyfy.object as? Node, node.parent == parentNode {
            if let index = nodes.index(of: node) {
                collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            }
        }
    }

    func refresh() {
        UIView.animate(withDuration: 0.2, animations: {
            self.collectionView.alpha = 0
            self.navigationItem.titleView?.alpha = 0
        }, completion: { _ in
            self.setupTitle(self.parentNode!.dislayName())
            self.nodes.removeAll()
            SVProgressHUD.show(withStatus: "Refresh...")
            DispatchQueue.global().async {
                self.nodes = Model.shared.nodes(byRoot: self.parentNode!)
                for node in self.nodes {
                    node.parent = self.parentNode
                    node.share = self.parentNode!.share
                }
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.collectionView.reloadData()
                    if let index = self.parentNode?.selectedIndexPath {
                        self.collectionView.selectItem(at: index, animated: false, scrollPosition: .centeredVertically)
                    }

                    if self.parentNode!.parent == nil {
                        self.navigationItem.setLeftBarButton(nil, animated: false)
                    } else {
                        let btn = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(self.goBack))
                        btn.tintColor = UIColor.white
                        self.navigationItem.setLeftBarButton(btn, animated: false)
                    }
                    UIView.animate(withDuration: 0.4, animations: {
                        self.navigationItem.titleView?.alpha = 1
                        self.collectionView.alpha = 1
                    }, completion: { _ in
                    })
                }
            }
        })
    }

    override func goBack() {
        if parentNode!.parent != nil {
            parentNode = parentNode!.parent
            refresh()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "search" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! SearchInfoController
            next.node = sender as? Node
        } else if segue.identifier == "info" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! InfoViewController
            next.node = sender as? Node
            next.metainfo = next.node!.info
        } else if segue.identifier == "movie" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! VideoPlayer
            next.node = sender as? Node
        }
    }
}

// MARK: - CollectionView

extension ContentController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "my_cell", for: indexPath) as! ContentCell
        cell.node = nodes[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let node = nodes[indexPath.row]
        if node.directory {
            parentNode = node
            if parentNode?.parent != nil {
                parentNode?.parent!.selectedIndexPath = indexPath
            }
            refresh()
        } else {
            self.performSegue(withIdentifier: "info", sender: node)
        }
    }
}

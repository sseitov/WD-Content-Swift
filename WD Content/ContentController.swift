//
//  ContentController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 24.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class ContentController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var parentNode:Node?
    var nodes:[Node] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshNotify),
                                               name: refreshNotification,
                                               object: nil)
        refresh()
    }

    func refreshNotify() {
        collectionView.reloadData()
    }
    
    func refresh() {
        UIView.animate(withDuration: 0.2, animations: {
            self.collectionView.alpha = 0
            self.navigationItem.titleView?.alpha = 0
        }, completion: { _ in
            self.setupTitle(self.parentNode!.name!)
            self.nodes = Model.shared.nodes(byRoot: self.parentNode)
            self.collectionView.reloadData()
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
            next.metainfo = sender as? MetaInfo
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
        if !node.isFile {
            parentNode = node
            refresh()
        } else {
            if node.info != nil {
                performSegue(withIdentifier: "info", sender: node.info)
            } else {
                performSegue(withIdentifier: "search", sender: node)
            }
        }
    }
}

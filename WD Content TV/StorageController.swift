//
//  StorageController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 22.07.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class StorageController: UICollectionViewController, UIGestureRecognizerDelegate {

    private var shares:[Share] = []
    private var focusedIndexPath:IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "MOVIES"
        
        _ = self.view.setGradientBackground(top: UIColor.mainColor(), bottom: UIColor.gradientColor(), size: self.view.frame.size)
        
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.pressLongTap(tap:)))
        longTap.delegate = self
        collectionView?.addGestureRecognizer(longTap)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refresh),
                                               name: refreshNotification,
                                               object: nil)
        self.collectionView?.remembersLastFocusedIndexPath = true
        
        self.shares = Model.shared.allShares()
        if shares.count == 0 {
            refresh()
        } else {
            focusedIndexPath = IndexPath(row: 0, section: 0)
            collectionView?.selectItem(at: focusedIndexPath, animated: true, scrollPosition: .top)
        }
    }
    
    @objc func refresh() {
        SVProgressHUD.show(withStatus: "Refresh...")
        Model.shared.refreshShares({ error in
            SVProgressHUD.dismiss()
            if error != nil {
                self.showMessage(error!.localizedDescription, messageType: .error)
            } else {
                self.shares = Model.shared.allShares()
                if self.shares.count == 0 {
                    self.performSegue(withIdentifier: "addShare", sender: nil)
                } else {
                    self.collectionView?.reloadData()
                }
            }
        })
    }
    
    @objc func pressLongTap(tap:UILongPressGestureRecognizer) {
        if tap.state == .began {
            if focusedIndexPath != nil && focusedIndexPath!.row < shares.count {
                let share = shares[focusedIndexPath!.row]
                let alert = UIAlertController(title: "Attention!", message: "Do you want to delete \(share.name!)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    SVProgressHUD.show(withStatus: "Delete...")
                    Model.shared.deleteShare(share, result: { _ in
                        SVProgressHUD.dismiss()
                        self.shares.remove(at: self.focusedIndexPath!.row)
                        self.collectionView?.deleteItems(at: [self.focusedIndexPath!])
                    })
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shares.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "storage", for: indexPath) as! StorageCell
        cell.name = shares[indexPath.row].displayName().uppercased()
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        focusedIndexPath = context.nextFocusedIndexPath
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "openFolder", sender: indexPath)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openFolder" {
            if let index = sender as? IndexPath {
                let controller = segue.destination as! FolderController
                controller.parentNode = Node(share: shares[index.row])
            }
        }
    }

}

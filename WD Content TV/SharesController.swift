//
//  SharesController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 29.12.16.
//  Copyright © 2016 Sergey Seitov. All rights reserved.
//

import UIKit
import SVProgressHUD

class SharesController: UICollectionViewController, UIGestureRecognizerDelegate {

	var parentNode:Node?
	var nodes:[Node] = []
	
	private var focusedIndexPath:IndexPath?
    
    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(self.refresh),
		                                       name: refreshNotification,
		                                       object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshNode(notyfy:)),
                                               name: refreshNodeNotification,
                                               object: nil)
		
		let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.pressLongTap(tap:)))
		longTap.delegate = self
		collectionView?.addGestureRecognizer(longTap)
		
        _ = self.view.setGradientBackground(top: UIColor.mainColor(), bottom: UIColor.gradientColor(), size: self.view.frame.size)

        refresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        refresh()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.first != nil && presses.first!.type == .menu {
            if parentNode == nil {
                super.pressesBegan(presses, with: event)
            } else {
                return
            }
        } else {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.first != nil && presses.first!.type == .menu {
            if parentNode != nil {
                parentNode = parentNode!.parent
                refresh()
            } else {
                super.pressesEnded(presses, with: event)
            }
        } else {
            super.pressesEnded(presses, with: event)
        }
    }

	func pressLongTap(tap:UILongPressGestureRecognizer) {
        if parentNode == nil {
            if tap.state == .began {
                if focusedIndexPath != nil, focusedIndexPath!.row > 0 {
                    let node = nodes[focusedIndexPath!.row - 1]
                    let alert = UIAlertController(title: "Attention!", message: "Do you want to delete \(node.name)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        SVProgressHUD.show(withStatus: "Delete...")
                        Model.shared.deleteShare(node.share!, result: { _ in
                            SVProgressHUD.dismiss()
                            self.nodes.remove(at: self.focusedIndexPath!.row - 1)
                            self.collectionView?.deleteItems(at: [self.focusedIndexPath!])
                        })
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    present(alert, animated: true, completion: nil)
                }
            }
        }
	}

    func refreshNode(notyfy:Notification) {
        if let node = notyfy.object as? Node, node.parent == parentNode {
            if let index = nodes.index(of: node) {
                collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            }
        }
    }
    
	func refresh() {
        let text = parentNode == nil ? "MY STORAGES" : parentNode!.dislayName()
        self.title = text.uppercased()
        if parentNode == nil {
            var shares = Model.shared.allShares()
            if shares.count == 0 {
                SVProgressHUD.show(withStatus: "Refresh...")
                Model.shared.refreshShares({ error in
                    SVProgressHUD.dismiss()
                    shares = Model.shared.allShares()
                    if shares.count == 0 {
                        self.performSegue(withIdentifier: "addShare", sender: nil)
                    } else {
                        self.nodes.removeAll()
                        for share in shares {
                            self.nodes.append(Node(share: share))
                        }
                        self.collectionView?.reloadData()
                    }
                    return
                })
            } else {
                self.nodes.removeAll()
                for share in shares {
                    self.nodes.append(Node(share: share))
                }
            }
        } else {
            self.nodes = Model.shared.nodes(byRoot: self.parentNode!)
            for node in self.nodes {
                node.parent = parentNode
                node.share = parentNode!.share
                node.info = Model.shared.getInfoForNode(node)
            }
        }
        self.collectionView?.reloadData()
	}

    // MARK: UICollectionView delegate

    override func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if let index = parentNode?.selectedIndexPath {
            return index
        } else {
            return nil
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return parentNode == nil ? nodes.count + 1 : nodes.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "share", for: indexPath) as! ShareCell
		if indexPath.row == 0 && parentNode == nil {
			cell.imageView.image = UIImage(named: "addShare")
			cell.textView.text = "ADD SHARE"
		} else {
			let node = parentNode == nil ? nodes[indexPath.row-1] : nodes[indexPath.row]
			cell.node = node
		}
        return cell
    }
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if parentNode == nil && indexPath.row == 0 {
			performSegue(withIdentifier: "addShare", sender: nil)
		} else  {
			let node = parentNode == nil ? nodes[indexPath.row-1] : nodes[indexPath.row]
			if !node.directory {
                parentNode?.selectedIndexPath = indexPath
                self.performSegue(withIdentifier: "info", sender: node)
			} else {
				parentNode = node
                if parentNode?.parent != nil {
                    parentNode?.parent!.selectedIndexPath = indexPath
                }
				refresh()
			}
		}
	}

	override func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
		focusedIndexPath = context.nextFocusedIndexPath
		return true
	}
	
	// MARK: - Navigation
	

    func movie(_ path: String!, startWithAudio channel: Int32) {
        if let node = Model.shared.node(byPath: path) {
            Model.shared.saveContext()
            if let index = nodes.index(of: node) {
                collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            }
        }
    }
    
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showDevice" {
			let controller = segue.destination as! DeviceController
			controller.target = sender as? ServiceHost
		} else if segue.identifier == "info" {
			let nav = segue.destination as! UINavigationController
			let next = nav.topViewController as! InfoViewController
			next.node = sender as? Node
		}
	}

}

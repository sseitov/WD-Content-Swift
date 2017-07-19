//
//  MainVC.swift
//  WD Content
//
//  Created by Сергей Сейтов on 24.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import AMSlideMenu

class MainVC: AMSlideMenuMainViewController, AMSlideMenuDelegate {

    private var rightMenuIsOpened = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isInitialStart = false
        self.slideMenuDelegate = self
    }

    override func primaryMenu() -> AMPrimaryMenu {
        return AMPrimaryMenuRight
    }
    
    // MARK: - Right menu
    
    override func initialIndexPathForRightMenu() -> IndexPath! {
        return IndexPath(row: 0, section: 0)
    }
    
    override func segueIdentifierForIndexPath(inRightMenu indexPath: IndexPath!) -> String! {
        let shares = Model.shared.allShares()
        if shares.count > 0 {
            return "content"
        } else {
            Model.shared.refreshShares({ _ in
                self.openRightMenu(animated: true)
            })
            return "shares"
        }
    }
    
    override func rightMenuWidth() -> CGFloat {
        return 260
    }

    override func configureRightMenuButton(_ button: UIButton!) {
        button.frame = CGRect(x: 0, y: 0, width: 25, height: 13)
        button.backgroundColor = UIColor.clear
        button.setImage(UIImage(named:"menuButton"), for: .normal)
    }

    override func configureSlideLayer(_ layer: CALayer!) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 5
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: self.view.layer.bounds).cgPath
    }
    
    override func openAnimationCurve() -> UIViewAnimationOptions {
        return .curveEaseOut
    }
    
    override func closeAnimationCurve() -> UIViewAnimationOptions {
        return .curveEaseOut
    }

    override func deepnessForLeftMenu() -> Bool {
        return false
    }

    override func deepnessForRightMenu() -> Bool {
        return true
    }
    
    override func maxDarknessWhileLeftMenu() -> CGFloat {
        return 0.5
    }
    
    override func maxDarknessWhileRightMenu() -> CGFloat {
        return 0.5
    }
    
    private func rightMenuFrame() -> CGRect {
        return CGRect(x: self.view.bounds.size.width - rightMenuWidth(), y: 0, width: rightMenuWidth(), height: self.view.bounds.size.height)
    }
    
    override func openRightMenu(animated: Bool) {
        super.openRightMenu(animated: animated)
        self.rightMenu.view.frame = rightMenuFrame()
    }
    
    func rightMenuWillOpen() {
        rightMenuIsOpened = true
    }
    
    func rightMenuDidClose() {
        rightMenuIsOpened = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if rightMenuIsOpened {
            self.currentActiveNVC.view.alpha = 0
            coordinator.animate(alongsideTransition: { (context: UIViewControllerTransitionCoordinatorContext) in
                self.rightMenu.view.frame = self.rightMenuFrame()
            }) { (context: UIViewControllerTransitionCoordinatorContext) in
                UIView.animate(withDuration: 0.2, animations: {
                    self.currentActiveNVC.view.alpha = 1
                })
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

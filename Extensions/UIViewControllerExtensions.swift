//
//  UIViewControllerExtensions.swift
//  iNear
//
//  Created by Сергей Сейтов on 28.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit

enum MessageType {
    case error, success, information
}

#if IOS
extension UINavigationController {
    
    open override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.topViewController
    }
    
    open override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.topViewController
    }
}
#endif

extension UIViewController {

    func setupTitle(_ text:String, color:UIColor = UIColor.mainColor()) {
    #if TV
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 800, height: 132))
        label.textColor = color
        label.font = UIFont.mainFont()
    #else
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        label.textColor = UIColor.white
        label.font = UIFont.condensedFont()
    #endif
        label.textAlignment = .center
        label.text = text
        
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        navigationItem.titleView = label
    }
    
    func setupBackButton() {
        navigationItem.leftBarButtonItem?.target = self
        navigationItem.leftBarButtonItem?.action = #selector(UIViewController.goBack)
    }
    
    @objc func goBack() {
         _ = self.navigationController!.popViewController(animated: true)
    }
    
    // MARK: - alerts
    
    func showMessage(_ error:String, messageType:MessageType, messageHandler: (() -> ())? = nil) {
        var title:String = ""
        switch messageType {
        case .success:
            title = "Success"
        case .information:
            title = "Information"
        default:
            title = "Error"
        }
        let alert = UIAlertController(title: title.uppercased(), message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { _ in
            if messageHandler != nil {
                messageHandler!()
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
}

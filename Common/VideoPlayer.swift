//
//  VideoPlayer.swift
//  WD Content
//
//  Created by Сергей Сейтов on 26.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class VideoPlayer: UIViewController, VLCMediaPlayerDelegate, VLCMediaDelegate {

    @IBOutlet weak var movieView: UIView!
    
    var node:Node?
    
    var mediaPlayer:VLCMediaPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    #if IOS
        setupBackButton()
    #endif
        VLCLibrary.shared().debugLogging = true
        
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
    }
    
#if IOS
    override func goBack() {
        mediaPlayer.delegate = nil
        mediaPlayer.stop()
        dismiss(animated: true, completion: nil)
    }
#else
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.first != nil && presses.first!.type == .menu {
            mediaPlayer.delegate = nil
            mediaPlayer.stop()
        }
        super.pressesBegan(presses, with: event)
    }
#endif
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let urlStr = "smb://\(self.node!.share!.user!):\(self.node!.share!.password!)@\(self.node!.share!.ip!)\(self.node!.filePath)"
        let urlStrCode = urlStr.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        if let url = URL(string: urlStrCode!) {
            self.mediaPlayer.media = VLCMedia(url: url)
            self.mediaPlayer.play()
        } else {
            self.showMessage("Can not open file.", messageType: .error, messageHandler: {
                self.dismiss(animated: true, completion: nil)
            })
        }
/*
        SVProgressHUD.show(withStatus: "Open...")
        DispatchQueue.global().async {
            var url:URL?
            if self.node!.path!.contains(" ") {
                let newPath:String? = self.node!.path!.replacingOccurrences(of: " ", with: "_", options: [], range: nil)
                let connection = SMBConnection()
                if connection.connect(to: self.node!.connection!.ip!, port: self.node!.connection!.port, user: self.node!.connection!.user!, password: self.node!.connection!.password!) {
                    
                    if (connection.renameFile(self.node!.path!, newPath: newPath!)) {
                        let urlStr = "smb://\(self.node!.connection!.user!):\(self.node!.connection!.password!)@\(self.node!.connection!.ip!)\(newPath!)"
                        let urlStrCode = urlStr.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
                        url = URL(string: urlStrCode!)
                    }
                }
            } else {
                let urlStr = "smb://\(self.node!.connection!.user!):\(self.node!.connection!.password!)@\(self.node!.connection!.ip!)\(self.node!.path!)"
                let urlStrCode = urlStr.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
                url = URL(string: urlStrCode!)
            }
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
            }
        }
 */
    }
}

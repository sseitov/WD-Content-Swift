//
//  VideoPlayer.swift
//  WD Content
//
//  Created by Сергей Сейтов on 26.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class VideoPlayer: UIViewController, VLCMediaPlayerDelegate {

    @IBOutlet weak var movieView: UIView!
    
    var node:Node?
    
    private var mediaPlayer:VLCMediaPlayer!
    private var barHidden = false
    private var buffering = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    #if IOS
        setupBackButton()
    #endif
//        VLCLibrary.shared().debugLogging = true
        
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapScreen))
        movieView.addGestureRecognizer(tap)
        
        navigationItem.rightBarButtonItem?.isEnabled = false
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
    
    func tapScreen() {
        barHidden = !barHidden
        navigationController?.setNavigationBarHidden(barHidden, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let urlStr = "smb://\(self.node!.share!.user!):\(self.node!.share!.password!)@\(self.node!.share!.ip!)\(self.node!.filePath)"
        let urlStrCode = urlStr.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        if let url = URL(string: urlStrCode!) {
            self.mediaPlayer.media = VLCMedia(url: url)
            self.mediaPlayer.play()
            tapScreen()
            navigationItem.rightBarButtonItem?.isEnabled = true
        } else {
            self.showMessage("Can not open file.", messageType: .error, messageHandler: {
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    private func printPlayerState(_ state:VLCMediaPlayerState) {
        switch state {
        case .error:
            print("=============== error")
        case .opening:
            print("=============== opening")
        case .buffering:
            print("=============== buffering")
        case .playing:
            print("=============== playing")
        case .paused:
            print("=============== paused")
        case .stopped:
            print("=============== stopped")
        case .ended:
            print("=============== ended")
        }
    }
    
    private func printMediaState(_ state:VLCMediaState) {
        switch state {
        case .buffering:
            print("=============== media buffering")
        case .playing:
            print("=============== media playing")
        case .error:
            print("=============== media error")
        case .nothingSpecial:
            print("=============== media nothingSpecial")
        }
    }
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        printPlayerState(mediaPlayer.state)
        printMediaState(mediaPlayer.media.state)
        switch mediaPlayer.state {
        case .stopped:
            mediaPlayer.delegate = nil
            mediaPlayer.stop()
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectTrack" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! TrackController
            next.player = mediaPlayer
        }
    }

}

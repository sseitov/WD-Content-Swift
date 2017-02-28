//
//  VideoPlayer.swift
//  WD Content
//
//  Created by Сергей Сейтов on 26.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit
import SVProgressHUD

class VideoPlayer: UIViewController, VLCMediaPlayerDelegate, TrackControllerDelegate {

    @IBOutlet weak var movieView: UIView!
    
    var node:Node?
    
    private var mediaPlayer:VLCMediaPlayer!
    private var buffering = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nodeTitle = node!.info != nil ? node!.info!.title! : node!.dislayName()
        setupTitle(nodeTitle)
        
    #if IOS
        setupBackButton()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapScreen))
        movieView.addGestureRecognizer(tap)
    #endif
//        VLCLibrary.shared().debugLogging = true
        
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
        
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

    }
    
#if IOS
    override func goBack() {
        mediaPlayer.delegate = nil
        mediaPlayer.stop()
        dismiss(animated: true, completion: nil)
    }
    
    private var barHidden = false
    private var firstTap = false
    
    func tapScreen() {
        firstTap = true
        barHidden = !barHidden
        UIApplication.shared.setStatusBarHidden(barHidden, with: .slide)
        navigationController?.setNavigationBarHidden(barHidden, animated: true)
        navigationController?.setToolbarHidden(barHidden, animated: true)
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
        case .buffering:
            if mediaPlayer.media.state == .playing {
                SVProgressHUD.dismiss()
                if !firstTap {
                    tapScreen()
                }
            } else {
                SVProgressHUD.show(withStatus: "Buffering...")
            }
        case .stopped:
            mediaPlayer.delegate = nil
            mediaPlayer.stop()
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
    
    // MARK: - Navigation
    
    func didSelectTrack(_ track:Int32) {
        dismiss(animated: true, completion: {
            print("set audio track to \(track)")
            self.mediaPlayer.currentAudioTrackIndex = track
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectTrack" {
            let nav = segue.destination as! UINavigationController
            let next = nav.topViewController as! TrackController
            next.player = mediaPlayer
            next.delegate = self
        }
    }

}

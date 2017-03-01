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

#if IOS
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var toolbarConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderItem: UIBarButtonItem!
    @IBOutlet weak var timeItem: UIBarButtonItem!
    @IBOutlet weak var positionSlider: UISlider!
    @IBOutlet weak var toolbar: UIToolbar!
#endif
    var node:Node?
    
    private var mediaPlayer:VLCMediaPlayer!
    private var buffering = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nodeTitle = node!.info != nil ? node!.info!.title! : node!.dislayName()
        setupTitle(nodeTitle, color: UIColor.white)
        setupBackButton()
        
    #if IOS
        positionSlider.addTarget(self, action: #selector(self.sliderBeganTracking(_:)), for: .touchDown)
        let events = UIControlEvents.touchUpInside.union(UIControlEvents.touchUpOutside)
        positionSlider.addTarget(self, action: #selector(self.sliderEndedTracking(_:)), for: events)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapScreen))
        movieView.addGestureRecognizer(tap)
    #endif
//        VLCLibrary.shared().debugLogging = true
        
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer.delegate = self
    #if IOS
        mediaPlayer.drawable = movieView
    #else
        mediaPlayer.drawable = self.view
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapScreen))
        self.view.addGestureRecognizer(tap)
    #endif

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
    
    deinit {
    #if TV
        mediaPlayer.delegate = nil
        mediaPlayer.stop()
    #endif
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
#if IOS
        sliderItem.width = view.frame.width - 100
#endif
    }
    
    override func goBack() {
    #if IOS
        mediaPlayer.delegate = nil
        mediaPlayer.stop()
        dismiss(animated: true, completion: nil)
    #else
        tapScreen()
    #endif
    }
    
#if TV
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        tapScreen()
        super.pressesEnded(presses, with: event)
    }
#endif
    
    private var barHidden = false
    private var firstTap = false
    
    func tapScreen() {
        firstTap = true
        barHidden = !barHidden
    #if IOS
        UIApplication.shared.setStatusBarHidden(barHidden, with: .slide)
        toolbarConstraint.constant = barHidden ? 0 : 44
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        })
    #endif
        navigationController?.setNavigationBarHidden(barHidden, animated: true)
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
//        printPlayerState(mediaPlayer.state)
//        printMediaState(mediaPlayer.media.state)
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
#if IOS
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        if let t = Int32(mediaPlayer.remainingTime.minuteStringValue) {
            let h = t/60
            let m = t % 60
            timeItem.title = String(format: "%d:%.2d", h, m)
        }
        positionSlider.value = mediaPlayer.position
    }
    
    func sliderBeganTracking(_ slider: UISlider!) {
        mediaPlayer.pause()
    }
    
    func sliderEndedTracking(_ slider: UISlider!) {
        mediaPlayer.position = slider.value
        mediaPlayer.pause()
    }
    
    @IBAction func playPause(_ sender: Any) {
        mediaPlayer.pause()
        let btn = mediaPlayer.isPlaying ?
            UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(self.playPause(_:))) :
            UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(self.playPause(_:)))
        btn.tintColor = UIColor.white
        var items = toolbar.items!
        items.remove(at: 0)
        items.insert(btn, at: 0)
        toolbar.setItems(items, animated: true)
    }
#endif

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

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
    
#if IOS
    @IBOutlet weak var toolbarConstraint: NSLayoutConstraint!
    @IBOutlet weak var sliderItem: UIBarButtonItem!
    @IBOutlet weak var timeItem: UIBarButtonItem!
    @IBOutlet weak var positionSlider: UISlider!
    @IBOutlet weak var toolbar: UIToolbar!
#else
    @IBOutlet weak var controlConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var movieProgress: UIProgressView!
    @IBOutlet weak var movieTime: UILabel!
#endif

    var nodes:[Node] = []
    
    private var mediaPlayer:VLCMediaPlayer!
    private var buffering = false
    private var position:Int = 0
    private var currentNode:Node?
    private var nodeIndex:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    #if IOS
        setupBackButton()
        positionSlider.addTarget(self, action: #selector(self.sliderBeganTracking(_:)), for: .touchDown)
        let events = UIControlEvents.touchUpInside.union(UIControlEvents.touchUpOutside)
        positionSlider.addTarget(self, action: #selector(self.sliderEndedTracking(_:)), for: events)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapScreen))
        movieView.addGestureRecognizer(tap)
        toolbar.backgroundColor = UIColor.mainColor()
    #else
        audioButton.isEnabled = false
        pauseButton.isEnabled = false
        rewindButton.isEnabled = false
        forwardButton.isEnabled = false

        let menuTap = UITapGestureRecognizer(target: self, action: #selector(self.menuTap))
        menuTap.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        self.view.addGestureRecognizer(menuTap)
    #endif
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
        nodeIndex = 0
        playNode(nodes[nodeIndex])
    }
    
    deinit {
    #if TV
        mediaPlayer.delegate = nil
        mediaPlayer.stop()
    #endif
    }
    
    private func playNode(_ node:Node?) {
        if node == nil {
            return
        }
        
        currentNode = node;
        
        let nodeTitle = node!.info != nil ? node!.info!.title! : node!.dislayName()
        setupTitle(nodeTitle, color: UIColor.white)
       
        var user = node!.share!.user!
        if user.isEmpty {
            user = "guest"
        }
        var password = node!.share!.password!
        if password.isEmpty {
            password = "anonymous"
        }
        let urlStr = "smb://\(user):\(password)@\(node!.share!.ip!)\(node!.filePath)"
        print(urlStr)
        let urlStrCode = urlStr.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        if let url = URL(string: urlStrCode!) {
            self.mediaPlayer.media = VLCMedia(url: url)
            self.mediaPlayer.play()
            self.position = 0
            if node!.info != nil {
                Model.shared.setViewed(node!.info!)
            }
        } else {
            self.showMessage("Can not open file.", messageType: .error, messageHandler: {
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
#if IOS
        sliderItem.width = view.frame.width - 100
#endif
    }
    
    override func goBack() {
        mediaPlayer.delegate = nil
        mediaPlayer.stop()
        SVProgressHUD.dismiss()
        dismiss(animated: true, completion: nil)
    }
    
#if TV
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        tapScreen()
    }
  
    func menuTap() {
        if barHidden {
            goBack()
        } else {
            tapScreen()
        }
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
    #else
        audioButton.isEnabled = !barHidden
        pauseButton.isEnabled = !barHidden
        rewindButton.isEnabled = !barHidden
        forwardButton.isEnabled = !barHidden
        controlConstraint.constant = barHidden ? -128 : 0
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        })
    #endif
        navigationController?.setNavigationBarHidden(barHidden, animated: true)
    }
    
    private func printPlayerState(_ state:VLCMediaPlayerState) {
        switch state {
        case .stopped:
            print("!!!!! Player state: stopped")
        case .opening:
            print("!!!!! Player state: opening")
        case .buffering:
            print("!!!!! Player state: buffering")
        case .ended:
            print("!!!!! Player state: ended")
        case .error:
            print("!!!!! Player state: error")
        case .playing:
            print("!!!!! Player state: playing")
        case .paused:
            print("!!!!! Player state: paused")
        }
    }
    
    private func printMediaState(_ state:VLCMediaState) {
        switch state {
        case .nothingSpecial:
            print("===== Media state: nothingSpecial")
        case .buffering:
            print("===== Media state: buffering")
        case .playing:
            print("===== Media state: playing")
        case .error:
            print("===== Media state: error")
        }
    }
    
    private func startBuffering() {
        if !buffering {
            buffering = true
            SVProgressHUD.show(withStatus: "Buffering...")
        }
    }
    
    private func stopBuffering() {
        if buffering {
            buffering = false
            SVProgressHUD.dismiss()
            if !firstTap {
                if let info = self.currentNode?.info {
                    if info.audioChannel >= 0 {
                        self.mediaPlayer.currentAudioTrackIndex = info.audioChannel
                        self.mediaPlayer.currentVideoSubTitleIndex = info.subtitleChannel
                    } else {
                        Model.shared.setAudioChannel(info, channel: Int(self.mediaPlayer.currentAudioTrackIndex))
                        Model.shared.setSubtitleChannel(info, channel: Int(self.mediaPlayer.currentVideoSubTitleIndex))
                    }
                }
                tapScreen()
            }
        }
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        switch mediaPlayer.state {
        case .buffering:
            startBuffering()
        case .stopped:
            nodeIndex += 1
            mediaPlayer.stop()
            if nodeIndex < nodes.count {
                playNode(nodes[nodeIndex])
            } else {
                mediaPlayer.delegate = nil
                SVProgressHUD.dismiss()
                dismiss(animated: true, completion: nil)
            }
        default:
            break
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        stopBuffering()
        let sec = mediaPlayer.time.value.intValue / 1000
        if self.position < sec {
            self.position = sec
            #if IOS
                timeItem.title = mediaPlayer.remainingTime.stringValue
                positionSlider.value = mediaPlayer.position
            #else
                movieTime.text = mediaPlayer.remainingTime.stringValue
                movieProgress.progress = mediaPlayer.position
            #endif
        }
    }

#if IOS
    func sliderBeganTracking(_ slider: UISlider!) {
        mediaPlayer.pause()
    }
    
    func sliderEndedTracking(_ slider: UISlider!) {
        self.position = 0
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
#else
    @IBAction func rewind(_ sender: UIButton) {
        if mediaPlayer.position > 0.05 {
            mediaPlayer.position -= 0.05
        } else {
            mediaPlayer.position = 0
        }
        self.position = 0
    }
    
    @IBAction func forward(_ sender: UIButton) {
        if mediaPlayer.position < 0.95 {
            mediaPlayer.position += 0.05
        } else {
            mediaPlayer.position = 1
        }
        self.position = 0
    }
    
    @IBAction func pause(_ sender: UIButton) {
        mediaPlayer.pause()
        let isPlaying = mediaPlayer.isPlaying
        let normal = isPlaying ? UIImage(named: "playControlOff") : UIImage(named: "pauseControlOff")
        sender.setImage(normal, for: .normal)
        let active = isPlaying ? UIImage(named: "playControl") : UIImage(named: "pauseControl")
        sender.setImage(active, for: .focused)
        rewindButton.isEnabled = !isPlaying
        forwardButton.isEnabled = !isPlaying
    }
#endif

    // MARK: - Navigation

    func didSelectAudioTrack(_ track:Int32) {
        dismiss(animated: true, completion: {
            if let info = self.currentNode?.info {
                Model.shared.setAudioChannel(info, channel: Int(track))
            }
            self.mediaPlayer.currentAudioTrackIndex = track
        })
    }

    func didSelectSubtitleChannel(_ channel: Int32) {
        dismiss(animated: true, completion: {
            if let info = self.currentNode?.info {
                Model.shared.setSubtitleChannel(info, channel: Int(channel))
            }
            self.mediaPlayer.currentVideoSubTitleIndex = channel
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

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
    @IBOutlet weak var toolbarConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeIndicator: UILabel!
    @IBOutlet weak var positionSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        get {
            return barHidden
        }
    }

    var nodes:[Node] = []
    
    private var mediaPlayer:VLCMediaPlayer!
    private var buffering = false
    private var position:Int = 0
    private var currentNode:Node?
    private var nodeIndex:Int = 0
    private var mediaTime:VLCTime?
    private var mediaTitle:String = ""
    
    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        
        positionSlider.addTarget(self, action: #selector(self.sliderBeganTracking(_:)), for: .touchDown)
        positionSlider.addTarget(self, action: #selector(self.sliderTracking(_:)), for: .valueChanged)
        let events = UIControlEvents.touchUpInside.union(UIControlEvents.touchUpOutside)
        positionSlider.addTarget(self, action: #selector(self.sliderEndedTracking(_:)), for: events)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapScreen))
        movieView.addGestureRecognizer(tap)
        positionSlider.setThumbImage(UIImage(named: "slider"), for: UIControlState())
        
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer.delegate = self
        mediaPlayer.drawable = movieView
        nodeIndex = 0
        playNode(nodes[nodeIndex])
    }
    
    override func goBack() {
        mediaPlayer.delegate = nil
        mediaPlayer.stop()
        SVProgressHUD.dismiss()
        dismiss(animated: true, completion: nil)
    }
    
    private var barHidden = false
    private var firstTap = false
    
    @objc func tapScreen() {
        firstTap = true
        barHidden = !barHidden
        toolbarConstraint.constant = barHidden ? 0 : 44
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        })
        navigationController?.setNavigationBarHidden(barHidden, animated: true)
    }

    private func playNode(_ node:Node?) {
        if node == nil {
            return
        }
        
        currentNode = node;
        
        mediaTitle = node!.info != nil ? node!.info!.title! : node!.dislayName()
        setupTitle(mediaTitle, color: UIColor.white)
       
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
    
    // MARK: - Player states

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
        case .esAdded:
            print("!!!!! Player state: esAdded")
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
//        printPlayerState(mediaPlayer.state)
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
            if mediaTime == nil {
                mediaTime = mediaPlayer.remainingTime
                if mediaTime != nil {
                    if let time = VLCTime(int: -mediaTime!.intValue) {
                        setupTitle(mediaTitle + " (" + time.stringValue + ")", color: UIColor.white)
                    }
                }
            }
            self.position = sec
            timeIndicator.text = mediaPlayer.time.stringValue //mediaPlayer.remainingTime.stringValue
            positionSlider.value = mediaPlayer.position
        }
        if mediaPlayer.isPlaying {
            playPauseButton.setImage(UIImage(named: "mediaPause"), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(named: "mediaPlay"), for: .normal)
        }
    }

    @objc
    func sliderBeganTracking(_ slider: UISlider!) {
        mediaPlayer.pause()
    }
    
    @objc
    func sliderTracking(_ slider: UISlider!) {
        if mediaTime != nil {
            if let time = VLCTime(int: Int32(mediaTime!.value.doubleValue * Double(-slider.value))) {
                timeIndicator.text = time.stringValue
            }
        }
    }

    @objc
    func sliderEndedTracking(_ slider: UISlider!) {
        self.position = 0
        mediaPlayer.position = slider.value
        mediaPlayer.play()
    }
    
    @IBAction func playPause(_ sender: UIButton) {
        if mediaPlayer.isPlaying {
            mediaPlayer.pause()
            sender.setImage(UIImage(named: "mediaPlay"), for: .normal)
        } else {
            mediaPlayer.play()
            sender.setImage(UIImage(named: "mediaPause"), for: .normal)
        }
    }

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

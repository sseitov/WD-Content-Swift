//
//  VideoController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 25.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class VideoController: UIViewController, DemuxerDelegate {

    var node:Node?
    
    let demuxer = Demuxer()
    let videoOutput = AVSampleBufferDisplayLayer()
    
    var stopped = true
    var barsHidden = false
    var audioChannels:[Any]?
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle(node!.info != nil ? node!.info!.title! : node!.name!)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapOnScreen))
        self.view.addGestureRecognizer(tap)
        
        demuxer.delegate = self
        
        videoOutput.videoGravity = AVLayerVideoGravityResizeAspect
        videoOutput.backgroundColor = UIColor.black.cgColor
        Demuxer.setTimebaseFor(videoOutput)
        self.view.layer.addSublayer(videoOutput)
        
        SVProgressHUD.show(withStatus: "Loading...")
        DispatchQueue.global().async {
            self.audioChannels = self.demuxer.open(withPath: self.node!.path!,
                                                   host: self.node!.connection!.ip!,
                                                   port: self.node!.connection!.port,
                                                   user: self.node!.connection!.user!,
                                                   password: self.node!.connection!.password!)
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                if self.audioChannels == nil || self.audioChannels!.count == 0 {
                    self.showMessage("Error reading movie or media format not supported", messageType: .error, messageHandler: {
                        self.finish()
                    })
                } else {
                    if self.audioChannels!.count == 1 {
                        if let channel = self.audioChannels![0] as? [String:Any], let num = channel["channel"] as? Int {
                            self.play(audioChannel: Int32(num))
                        }
                    } else {
                        let alert = UIAlertController(title: nil, message: "Choose audio channel", preferredStyle: .actionSheet)
                        for item in self.audioChannels! {
                            if let channel = item as? [String:Any] {
                                alert.addAction(UIAlertAction(title: channel["codec"] as? String, style: .default, handler: { _ in
                                    if let num = channel["channel"] as? Int {
                                        self.play(audioChannel: Int32(num))
                                    }
                                }))
                            }
                        }
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                            self.finish()
                        }))
                        if(IS_PAD()) {
                            alert.modalPresentationStyle = .popover
                            let popover = alert.popoverPresentationController!
                            popover.permittedArrowDirections = .up
                            popover.barButtonItem = self.navigationItem.rightBarButtonItem
                        }
                        self.present(alert, animated: true, completion:nil)
                    }
                }
            }
        }
    }
    
    func layoutScreen() {
        videoOutput.bounds = self.view.bounds
        videoOutput.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        layoutScreen()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        layoutScreen()
    }
    
    func tapOnScreen() {
        barsHidden = !barsHidden
        navigationController?.setNavigationBarHidden(barsHidden, animated: true)
    }
    
    // MARK: - actions
    
    private func play(audioChannel:Int32) {
        if !demuxer.play(audioChannel) {
            showMessage("Error reading movie or media format not supported", messageType: .error, messageHandler: {
                self.finish()
            })
        }
        stopped = false
        videoOutput.requestMediaDataWhenReady(on: DispatchQueue.main, using: {
            while (!self.stopped && self.videoOutput.isReadyForMoreMediaData) {
                if !self.demuxer.enqueBuffer(on: self.videoOutput) {
                    break
                }
            }
        })
    }
    
    private func stop() {
        if stopped {
            return
        }
        stopped = true
        videoOutput.flushAndRemoveImage()
        demuxer.close()
    }
    
    @IBAction func finish() {
        stop()
        SVProgressHUD.dismiss()
        dismiss(animated: true, completion: nil)
    }

    @IBAction func changeAudio() {
        if audioChannels == nil {
            return
        }
        let alert = UIAlertController(title: nil, message: "Choose audio channel", preferredStyle: .actionSheet)
        for item in audioChannels! {
            if let channel = item as? [String:Any] {
                alert.addAction(UIAlertAction(title: channel["codec"] as? String, style: .default, handler: { _ in
                    if let num = channel["channel"] as? Int {
                        self.demuxer.changeAudio(Int32(num))
                    }
                }))
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if(IS_PAD()) {
            alert.modalPresentationStyle = .popover
            let popover = alert.popoverPresentationController!
            popover.permittedArrowDirections = .up
            popover.barButtonItem = self.navigationItem.rightBarButtonItem
        }
        self.present(alert, animated: true, completion:nil)
    }
    
    // MARK: - Demuxer delegate

    func demuxer(_ demuxer: Demuxer!, buffering: Bool) {
        DispatchQueue.main.async {
            if buffering {
                SVProgressHUD.show(withStatus: "Buffering...")
            } else {
                SVProgressHUD.dismiss()
            }
        }
    }
}

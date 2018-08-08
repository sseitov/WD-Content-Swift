//
//  TrackController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 28.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

protocol TrackControllerDelegate {
    func didSelectAudioTrack(_ track:Int32)
    func didSelectSubtitleChannel(_ channel:Int32)
}

class TrackController: UITableViewController {

    var player:VLCMediaPlayer?
    var delegate:TrackControllerDelegate?
    
#if IOS
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
#endif

    override func viewDidLoad() {
        super.viewDidLoad()
        #if IOS
            setupTitle("Audio channel and subtitles")
            setupBackButton()
        #else
            self.title = "Audio channel and subtitles"
            if let image = UIImage(named: "settings.png") {
                self.view.layer.contents = image.cgImage
                self.view.layer.contentsGravity = "resizeAspectFill"
            }
        #endif
    }

    override func goBack() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "audio channel" : "subtitles"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? Int(player!.numberOfAudioTracks) : Int(player!.numberOfSubtitlesTracks)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        if indexPath.section == 0 {
            cell.textLabel?.text = (player!.audioTrackNames as! [String])[indexPath.row]
            let index = (player!.audioTrackIndexes as! [Int32])[indexPath.row]
            if index == player!.currentAudioTrackIndex {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            cell.textLabel?.text = (player!.videoSubTitlesNames as! [String])[indexPath.row]
            let index = (player!.videoSubTitlesIndexes as! [Int32])[indexPath.row]
            if index == player!.currentVideoSubTitleIndex {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let index = indexPath.row == 0 ? -1 : (player!.audioTrackIndexes as! [Int])[indexPath.row]
            delegate?.didSelectAudioTrack(Int32(index))
        } else {
            let index = indexPath.row == 0 ? -1 : (player!.videoSubTitlesIndexes as! [Int])[indexPath.row]
            delegate?.didSelectSubtitleChannel(Int32(index))
        }
    }
}

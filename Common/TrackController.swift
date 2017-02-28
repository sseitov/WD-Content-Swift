//
//  TrackController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 28.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

protocol TrackControllerDelegate {
    func didSelectTrack(_ track:Int32)
}

class TrackController: UITableViewController {

    var player:VLCMediaPlayer?
    var delegate:TrackControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTitle("Select audio channel")
        setupBackButton()        
    }

    override func goBack() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(player!.numberOfAudioTracks)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.text = (player!.audioTrackNames as! [String])[indexPath.row]
        let index = (player!.audioTrackIndexes as! [Int32])[indexPath.row]
        if index == player!.currentAudioTrackIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row == 0 ? -1 : (player!.audioTrackIndexes as! [Int])[indexPath.row]
        delegate?.didSelectTrack(Int32(index))
    }
}

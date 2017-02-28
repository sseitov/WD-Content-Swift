//
//  TrackController.swift
//  WD Content
//
//  Created by Сергей Сейтов on 28.02.17.
//  Copyright © 2017 V-Channel. All rights reserved.
//

import UIKit

class TrackController: UITableViewController {

    weak var player:VLCMediaPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTitle("Select audio channel")
        setupBackButton()
        
        player?.pause()
    }

    override func goBack() {
        player?.pause()
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(player!.numberOfAudioTracks)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = (player!.audioTrackNames as! [String])[indexPath.row]
        if indexPath.row == Int(player!.currentAudioTrackIndex) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player?.audioChannel = Int32(indexPath.row)
        goBack()
    }
}

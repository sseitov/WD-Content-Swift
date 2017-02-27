//
//  SearchCell.swift
//  WD Content
//
//  Created by Сергей Сейтов on 20.02.17.
//  Copyright © 2017 Sergey Seitov. All rights reserved.
//

import UIKit
import SDWebImage

#if IOS
protocol SearchCellDelegate {
    func fieldDidChanged(_ text:String?)
}
#endif

class SearchCell: UITableViewCell, UITextFieldDelegate {

	@IBOutlet weak var field: UITextField!
#if IOS
    var delegate:SearchCellDelegate?
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            delegate?.fieldDidChanged(textField.text)
            return false
        } else {
            return true
        }
    }

#endif
	
}

class SearchResultCell: UITableViewCell {
	
	@IBOutlet weak var poster: UIImageView!
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var date: UILabel!
	
	var imagesBaseURL:String!
	
	var movie:[String:Any]? {
		didSet {
			if let name = movie!["title"] as? String {
				title.text = name
                title.font = UIFont.condensedFont()
                title.textColor = UIColor.mainColor()
			}
			if let release_date = movie!["release_date"] as? String {
				date.text = releaseDate(release_date)
                date.font = UIFont.mainFont()
			}
			if let poster_url = movie!["poster_path"] as? String, imagesBaseURL != nil {
				let url = URL(string: "\(imagesBaseURL!)\(poster_url)")
				poster.sd_setImage(with: url, placeholderImage: UIImage(named: "movie"))
			}
		}
	}
	
	
}

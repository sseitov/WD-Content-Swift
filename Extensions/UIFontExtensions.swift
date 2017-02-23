//
//  UIFontExtensions.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit

extension UIFont {
    
    class func mainFont() -> UIFont {
    #if TV
        return UIFont(name: "HelveticaNeue-Bold", size: 33)!
    #else
        return UIFont(name: "HelveticaNeue", size: 15)!
    #endif
    }
    
    class func thinFont() -> UIFont {
    #if TV
        return UIFont(name: "HelveticaNeue-Thin", size: 27)!
    #else
        return UIFont(name: "HelveticaNeue-Thin", size: 15)!
    #endif
    }
    
    class func condensedFont() -> UIFont {
    #if TV
        return UIFont(name: "HelveticaNeue-CondensedBold", size: 47)!
    #else
        return UIFont(name: "HelveticaNeue-CondensedBold", size: 17)!
    #endif
    }
}

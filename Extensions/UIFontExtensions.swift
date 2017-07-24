//
//  UIFontExtensions.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit

extension UIFont {
    
    #if TV
    class func mainFont(_ size:CGFloat = 37) -> UIFont {
        return UIFont(name: "HelveticaNeue-Bold", size: size)!
    }
    #else
    class func mainFont(_ size:CGFloat = 15) -> UIFont {
        return UIFont(name: "CalibreWeb-Regular", size: size)!
    }
    #endif
    
    #if TV
    class func thinFont(_ size:CGFloat = 27) -> UIFont {
        return UIFont(name: "HelveticaNeue", size: size)!
    }
    #else
    class func thinFont(_ size:CGFloat = 15) -> UIFont {
        return UIFont(name: "CalibreWeb-Light", size: size)!
    }
    #endif
    
    #if TV
    class func condensedFont(_ size:CGFloat = 47) -> UIFont {
        return UIFont(name: "HelveticaNeue-CondensedBold", size: size)!
    }
    #else
    class func condensedFont(_ size:CGFloat = 17) -> UIFont {
        return UIFont(name: "CalibreWeb-SemiBold", size: size)!
    }
    #endif
}

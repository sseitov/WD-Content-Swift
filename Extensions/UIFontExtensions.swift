//
//  UIFontExtensions.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.12.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit

extension UIFont {
    
    class func mainFont(_ size:CGFloat = 15) -> UIFont {
    #if TV
        return UIFont(name: "HelveticaNeue-Bold", size: 33)!
    #else
        return UIFont(name: "HelveticaNeue", size: size)!
    #endif
    }
    
    class func thinFont(_ size:CGFloat = 15) -> UIFont {
    #if TV
        return UIFont(name: "HelveticaNeue-Thin", size: 27)!
    #else
        return UIFont(name: "HelveticaNeue-Thin", size: size)!
    #endif
    }
    
    class func condensedFont(_ size:CGFloat = 17) -> UIFont {
    #if TV
        return UIFont(name: "HelveticaNeue-CondensedBold", size: 47)!
    #else
        return UIFont(name: "HelveticaNeue-CondensedBold", size: size)!
    #endif
    }
}

//
//  Configuration.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 11/1/15.
//
//

import Foundation
import UIKit

class Configuration {
    private enum Key: String {
        case UserImageKey
        case UserKey
        case UserNameKey
    }
    
    private var volatileStorage: [String : AnyObject] = [:]
    
    private static func fetchKey(key: String) -> AnyObject? {
        return NSUserDefaults.standardUserDefaults().objectForKey(key)
    }
    
    private static func setObject(object: AnyObject, forKey key: String) {
        NSUserDefaults.standardUserDefaults().setObject(object, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    static var UserName: String? {
        get {
        return fetchKey(Key.UserNameKey.rawValue) as? String
        }
        
        set {
            guard let name = newValue else { return }
            setObject(name, forKey: Key.UserNameKey.rawValue)
        }
    }
    
    static var UserImage: UIImage? {
        get {
        guard let data = fetchKey(Key.UserImageKey.rawValue) as? NSData else { return nil }
        return UIImage(data: data)
        }
        
        set {
            guard let
                image = newValue,
                data = UIImagePNGRepresentation(image)
                else {
                    NSLog("could not convert image to bytes :-(")
                    return
            }
            setObject(data, forKey: Key.UserImageKey.rawValue)
        }
    }
}

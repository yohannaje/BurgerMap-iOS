//
//  MenuViewController.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 9/21/15.
//
//

import UIKit
import ParseFacebookUtilsV4

extension PFUser {
    public typealias FetchProfileCallback = (name: String?, picture: UIImage?) -> ()
    func fetchProfile(callback: FetchProfileCallback? = nil) {
        NSLog("fetching profile data")
        let request = FBSDKGraphRequest(graphPath: "me", parameters: nil)
        request.startWithCompletionHandler {
            (connection, result, error) -> Void in
            guard let userData = result as? [NSObject : AnyObject] where error == nil else {
                NSLog("could not fetch profile data: \(error.localizedDescription)")
                return
            }
            
            guard let id = userData["id"] as? String else { return }
            NSLog("uid: \(id)")
            
            let pictureURL = {
                return NSURL(string: "https://graph.facebook.com/\(id)/picture?type=large&return_ssl_resources=1")!
                }()
            
            if let
                name = userData["name"] as? String,
                data = NSData(contentsOfURL: pictureURL),
                image = UIImage(data: data) {
                    Configuration.UserImage = image
                    Configuration.UserName = name
                    callback?(name: name, picture: image)
            }
        }
    }
}

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

class MenuViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let debug = false
        
        let afterFetchProfile: PFUser.FetchProfileCallback = {
            [unowned self] name, image in
            self.imageView.image = image
            self.nameLabel.text = name
        }
        
        afterFetchProfile(name: Configuration.UserName, picture: Configuration.UserImage)
        
        if let user = PFUser.currentUser() where !debug {
            user.fetchProfile(afterFetchProfile)
        } else {
            let permissions = ["user_about_me", "user_relationships", "user_location"]
            PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
                (user, error) -> Void in
                guard let user = user where error != nil else {
                    NSLog("could not log in")
                    return
                }
                NSLog("got user: \(user)")
                user.fetchProfile(afterFetchProfile)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        view.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(revealViewController().rearViewRevealWidth)
        }
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.cornerRadius = imageView.bounds.width / 2.0
        imageView.layer.masksToBounds = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}

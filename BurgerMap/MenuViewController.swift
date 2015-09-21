//
//  MenuViewController.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 9/21/15.
//
//

import UIKit
import ParseFacebookUtilsV4

class Configuration {
    enum Key: String {
        case UserKey
        case UserImageKey
    }
    
    static var sharedInstance = Configuration()
    private var store = [Key : AnyObject]()
    subscript(key: Key) -> AnyObject? {
        get {
            return store[key]
        }
        
        set {
            store[key] = newValue
        }
    }
}

class MenuViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let debug = true
        
        if let _ = PFUser.currentUser() where !debug {
            // do nothing...
        } else {
            let permissions = ["user_about_me", "user_relationships", "user_location"]
            PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
                (user, error) -> Void in
                if error != nil {
                    NSLog("could not log in")
                    return
                }
                Configuration.sharedInstance[.UserKey] = user
                NSLog("got user: \(user)")
                NSLog("fetching profile data")
                
                let request = FBSDKGraphRequest(graphPath: "me", parameters: nil)
                request.startWithCompletionHandler {
                    [unowned self](connection, result, error) -> Void in
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
                            Configuration.sharedInstance[.UserImageKey] = image
                            self.imageView.image = image
                            self.nameLabel.text = name
                    }
                }
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

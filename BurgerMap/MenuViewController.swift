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

class MenuHeaderView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var reviewsLabel: UILabel!
    @IBOutlet weak var checkinsLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.bounds.width / 2.0
        imageView.layer.masksToBounds = true
    }
    
    func updateView(name: String, image: UIImage?, reviews: Int, checkins: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            [unowned self] in
            self.imageView.image = image
            self.nameLabel.text = {
                _ -> String in
                let components = name.componentsSeparatedByString(" ")
                let lastName = components.last!
                let forename = components.dropLast().joinWithSeparator(" ")
                return "\(forename)\n\(lastName)"
                }()
            self.reviewsLabel.text = "\(reviews) reviews"
            self.checkinsLabel.text = "\(checkins) check-ins"
            self.layoutIfNeeded()
            
        }
    }
}

struct MenuShortcut {
    let action: String
    let title: String
    let iconName: String
    lazy var icon: UIImage = {
        //TODO: do this the right way here
        return UIImage(named: self.iconName)!
        }()
    
}

class MenuViewController: UIViewController {
    @IBOutlet weak var menuHeaderView: MenuHeaderView! {
        didSet {
            menuHeaderView.backgroundColor = .clearColor()
        }
    }
    @IBOutlet weak var menuTableView: UITableView!
    
    let categories = ["Joints", "Veggie", "Delivery"]
    let shortcuts = [
        (action: "addReview", title: "Add Review"),
        (action: "favorites", title: "Favorites"),
        (action: "checkin", title: "Check In"),
        (action: "settings", title: "Settings"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTableView.tableHeaderView = menuHeaderView
        menuTableView.contentInset = UIEdgeInsets(top: 66, left: 0, bottom: 0, right: 0)        
        menuHeaderView.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(menuTableView.snp_width)
        }
        menuTableView.setNeedsLayout()
    }
    
    override func viewWillAppear(animated: Bool) {
        fireProfileFetch()
    }
    
    func fireProfileFetch() {
        let debug = false
        let afterFetchProfile: PFUser.FetchProfileCallback = {
            [unowned self] name, image in
            guard let name = name else {
                NSLog("failed to get the user's name")
                return
            }
            self.menuHeaderView.updateView(name, image: image, reviews: 0, checkins: 0)
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
    
    override func viewDidAppear(animated: Bool) {
        NSLog("here")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MenuViewController: UITableViewDataSource {
    
    enum MenuSections: Int {
        case Filters = 0, Shortcuts
        static var sectionCount: Int { return 2 }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return MenuSections.sectionCount
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = MenuSections(rawValue: section) else { return 0 }
        switch section {
        case .Filters:
            return categories.count
        case .Shortcuts:
            return shortcuts.count
        }
    }
    
    private func filterCellForTableView(tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FilterCell", forIndexPath: indexPath)
        let text = categories[indexPath.row]
        cell.textLabel?.text = text
        return cell
        
    }
    
    private func shortcutCellForTableView(tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ShortcutCell", forIndexPath: indexPath)
        let (_, text) = shortcuts[indexPath.row]
        cell.textLabel?.text = text
        return cell
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let section = MenuSections(rawValue: indexPath.section) else { fatalError("requested a cell for a section that doesn't exist!") }
        switch section {
        case .Filters:
            return filterCellForTableView(tableView, atIndexPath: indexPath)
        case .Shortcuts:
            return shortcutCellForTableView(tableView, atIndexPath: indexPath)
        }
    }
}

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

class MenuHeaderView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var reviewsLabel: UILabel!
    @IBOutlet weak var checkinsLabel: UILabel!
    
    override func awakeFromNib() {
        //        translatesAutoresizingMaskIntoConstraints = false
    }
    
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
            self.reviewsLabel?.text = "\(reviews) reviews"
            self.checkinsLabel?.text = "\(checkins) check-ins"
            self.layoutIfNeeded()
            
        }
    }
}

class MenuCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.indentationWidth = 30.0
        self.indentationLevel = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let indentPoints = CGFloat(self.indentationLevel) * self.indentationWidth
        self.contentView.frame = CGRectMake(indentPoints, self.contentView.frame.origin.y,self.contentView.frame.size.width - indentPoints,self.contentView.frame.size.height)
    }
}

class MenuFilterCell: MenuCell {
}

class MenuShortcutCell: MenuCell {
    
    static func setupSeparator(separator: UIView) {
        separator.backgroundColor = UIColor.burgerSeparatorColor()
        separator.addConstraint(NSLayoutConstraint(
            item: separator, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 0.5))
        
    }
    
    @IBOutlet weak var topSeparator: UIView! {
        didSet {
            MenuShortcutCell.setupSeparator(topSeparator)
        }
    }
    
    @IBOutlet weak var bottomSeparator: UIView! {
        didSet {
            MenuShortcutCell.setupSeparator(bottomSeparator)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        showsTopSeparator = true
        showsBottomSeparator = false
    }
    
    var showsTopSeparator: Bool {
        get { return  topSeparator.hidden }
        set { topSeparator.hidden = !newValue }
    }
    
    var showsBottomSeparator: Bool {
        get { return  bottomSeparator.hidden }
        set { bottomSeparator.hidden = !newValue }
    }
    
}

protocol MenuSliderFilterCellDelegate {
    func menuSliderFilterCell(cell: MenuSliderFilterCell, sliderValueUpdated newValue: Float)
}

class MenuSpacerCell: MenuCell {
    override func awakeFromNib() {
        selectionStyle = .None
        contentView.addConstraint(NSLayoutConstraint(
            item: contentView,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: nil,
            attribute: .NotAnAttribute,
            multiplier: 1.0,
            constant: 5)
        )
    }
}

class MenuSliderFilterCell: MenuCell {
    var delegate: MenuSliderFilterCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //        selectionStyle = .None
        minLabel.text = String(format: "%d", arguments: [Int(slider.minimumValue) * 50])
        maxLabel.text = String(format: "%d", arguments: [Int(slider.maximumValue) * 50])
        slider.setThumbImage(UIImage(named: "knob"), forState: .Normal)
        valueChanged(nil)
    }
    
    private static func setupLabel(label: UILabel) {
        label.textColor = .burgerOrangeColor()
    }
    
    @IBOutlet weak var minLabel: UILabel! {
        didSet {
            MenuSliderFilterCell.setupLabel(minLabel)
        }
    }
    
    @IBOutlet weak var maxLabel: UILabel! {
        didSet {
            MenuSliderFilterCell.setupLabel(maxLabel)
        }
    }
    
    @IBOutlet weak var slider: UISlider! {
        didSet {
            slider.minimumTrackTintColor = UIColor.burgerOrangeColor()
            slider.addTarget(self, action: "valueChanged:", forControlEvents: .ValueChanged)
        }
    }
    
    @IBOutlet weak var valueLabel: UILabel! {
        didSet {
            valueLabel.textColor = .whiteColor()
        }
    }
    
    func valueChanged(sender: AnyObject?) {
        let value = 50 * Int(slider.value)
        //valueLabel.text = String(format: "%d", arguments: [value])
        delegate?.menuSliderFilterCell(self, sliderValueUpdated: Float(value))
    }
}

class MenuViewController: UIViewController {
    var menuHeaderView: MenuHeaderView! {
        return menuTableView.tableHeaderView as! MenuHeaderView
    }
    @IBOutlet weak var menuTableView: UITableView!
    
    // move this somewhere else
    var selectedCategories = [String]()
    
    let categories = [
        MenuFilter(value: "joints", title: "Burger Joints", iconName: "joint-hover", cellType: nil),
        MenuFilter(value: "vegetarian", title: "Vegetarian", iconName: "veggie", cellType: nil),
        MenuFilter(value: "open-now", title: "Open Now", iconName: "open", cellType: nil),
        MenuFilter(value: "delivery", title: "Delivery", iconName: "delivery", cellType: nil),
        MenuFilter(value: "takes-ccs", title: "Takes Credit Cards", iconName: "credit", cellType: nil),
        MenuFilter(value: "price", title: "", iconName: "credit", cellType: "SliderFilterCell"),
        MenuFilter(value: "", title: "", iconName:  "", cellType:  "MenuSpacerCell")
    ]
    
    let shortcuts = [
        MenuShortcut(action: "goReviews", title: "My Reviews", iconName: "reviews"),
        MenuShortcut(action: "goFavorites", title: "Favorites", iconName: "fav"),
        MenuShortcut(action: "goCheckIn", title: "Check In", iconName: "checkin"),
        MenuShortcut(action: "goSettings", title: "Settings", iconName: "settings"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        menuTableView.tableHeaderView = menuHeaderView
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
        // fix this later
        
        let item = categories[indexPath.row]
        let cellType = item.cellType ?? "FilterCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellType, forIndexPath: indexPath)
        
        cell.indentationLevel = indexPath.row == 0 ? 0 : 1
        if indexPath.row != 0 && selectedCategories.contains(item.value) {
            cell.accessoryView = UIImageView(image: UIImage(named: "tick"))
        } else {
            cell.accessoryView = nil
        }
        
        
        
        if let cell = cell as? MenuFilterCell {
            if indexPath.row == 0 {
                cell.titleLabel?.textColor = .blackColor()
                cell.contentView.backgroundColor = .burgerOrangeColor()
                cell.selectionStyle = .None
            } else {
                cell.titleLabel?.textColor = .whiteColor()
                cell.contentView.backgroundColor = .clearColor()
                cell.selectionStyle = .Default
            }
            cell.titleLabel?.text = item.title
            cell.iconImageView?.image = item.icon
        }
        return cell
        
    }
    
    private func shortcutCellForTableView(tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("ShortcutCell", forIndexPath: indexPath) as? MenuShortcutCell
            else { fatalError() }
        let item = shortcuts[indexPath.row]
        cell.titleLabel?.text = item.title
        cell.iconImageView?.image = item.icon
        cell.showsTopSeparator = indexPath.row == 0
        cell.showsBottomSeparator = true
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

extension MenuViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let item = categories[indexPath.row]
            if item.cellType == "MenuSpacerCell" { return }
            if let index = selectedCategories.indexOf(item.value) {
                selectedCategories.removeAtIndex(index)
            } else {
                selectedCategories.append(item.value)
            }
            
//            if item.value == "price" {
//                guard let
//                    cell = tableView.dataSource?.tableView(tableView, cellForRowAtIndexPath: indexPath) as? MenuSliderFilterCell
//                else { fatalError() }
//                cell.toggleSelected()
//                
//            }
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            let item = categories[indexPath.row]
            if item.cellType == "MenuSpacerCell" { return 5.0 }
        }
        return 42.0
    }
}

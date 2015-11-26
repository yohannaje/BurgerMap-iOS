//
//  BurgerDetailViewController.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 9/16/15.
//
//

import UIKit
import SnapKit
import SafariServices
import MapKit

struct User {
    static func getUser(id: String) -> User? {
        return nil
    }
    
    let id: String
    let username: String
    private let avatarURL: NSURL?
    
    init(username: String, avatarURL: NSURL?) {
        let id = NSUUID().UUIDString
        self.init(id: id, username: username, avatarURL: avatarURL)
    }
    
    internal init(id: String, username: String, avatarURL: NSURL?) {
        self.id = id
        self.username = username
        self.avatarURL = avatarURL
    }
}


class BurgerDetailInfo: NSObject {
    struct Review {
        let user: User!
        let content: String!
        let rating: Int!
        
        init?(userID: String, content: String, rating: Int) {
            guard let user = User.getUser(userID) else { return nil }
            self.user = user
            self.content = content
            self.rating = rating
        }
    }
    
    let headerImage: UIImage?
    let burgerWrapper: BurgerWrapper
    let reviews: [Review] = []
    
    
    init(headerImage: UIImage?, burgerWrapper: BurgerWrapper) {
        self.headerImage = headerImage
        self.burgerWrapper = burgerWrapper
    }
}

protocol BurgerCardDelegate {
    func checkinHandler(sender: AnyObject?)
    func reviewHandler(sender: AnyObject?)
    func websiteHandler(sender: AnyObject?)
    func callHandler(sender: AnyObject?)
    func directionsHandler(sender: AnyObject?)
}

class BurgerCard: UIView {
    
    var delegate: BurgerCardDelegate? {
        didSet {
            actionMap = {
                _ -> [UIButton: (AnyObject?) -> ()] in
                var m: [UIButton: (AnyObject?) -> ()] = [:]
                m[directionsButton] = delegate?.directionsHandler
                m[callButton] = delegate?.callHandler
                m[websiteButton] = delegate?.websiteHandler
                return m
                }()
        }
    }
    
    @IBOutlet weak var headerImageView: UIImageView! {
        didSet {
            headerImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var starRatingView: UIView! {
        didSet {
            //            starRatingView.clipsToBounds = true
            let label = starRatingLabel
            starRatingView.addSubview(label)
            label.snp_makeConstraints { (make) -> Void in
                make.left.right.top.bottom.equalTo(starRatingView)
            }
        }
    }
    lazy private var starRatingLabel: UILabel = {
        return UILabel()
    }()
    
    
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var addressTitleLabel: UILabel! { didSet { addressTitleLabel.text = NSLocalizedString("Address", comment: "Joint address title") } }
    @IBOutlet weak var phoneTitleLabel: UILabel! { didSet { phoneTitleLabel.text = NSLocalizedString("Phone", comment: "Joint address title") } }
    @IBOutlet weak var websiteTitleLabel: UILabel! { didSet { websiteTitleLabel.text = NSLocalizedString("Web", comment: "Joint address title") } }
    
    @IBOutlet weak var addressValueLabel: UILabel!
    @IBOutlet weak var phoneValueLabel: UILabel!
    @IBOutlet weak var websiteValueLabel: UILabel!
    
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var websiteButton: UIButton!
    
    private var actionMap: [UIButton : (AnyObject?) -> ()]!
    
    @IBAction func buttonHandler(sender: AnyObject?) {
        if let a = actionMap[sender as! UIButton] {
            a(sender)
        }
    }
    
    func setJoint(joint: BurgerWrapper) {
        nameLabel?.text = joint.name
        typeLabel?.text = "Joint"
        addressValueLabel?.text = joint.address
        phoneValueLabel?.text = joint.phone
        websiteValueLabel?.text = joint.website
        directionsButton.enabled = joint.hasAddress
        callButton.enabled = joint.hasPhone
        websiteButton.enabled = joint.hasWebsite
        setRating(joint)
    }
    
    private func setRating(joint: BurgerWrapper) {
        let s = (0..<5)
            .map { $0 < joint.rating ? UIColor.burgerStarRatingActiveColor() : UIColor.burgerStarRatingInactiveColor() }
            .map { NSAttributedString(string: "\u{2605}", attributes: [NSForegroundColorAttributeName : $0]) }
            .reduce(NSMutableAttributedString()) {
                $0.appendAttributedString($1)
                return $0
        }
        starRatingLabel.attributedText = s
    }
}

class BurgerDetailViewController: UIViewController {
    var reviewsHeader: UIView {
        let label = UILabel()
        label.text = "Reviews"
        label.backgroundColor = UIColor.clearColor()
        
        let container = UIView()
        container.backgroundColor = UIColor.burgerOrangeColor()
        container.addSubview(label)
        
        let button = UIButton()
        button.setImage(UIImage(named: "add"), forState: .Normal)
        container.addSubview(button)
        button.addTarget(self, action: "addReview:", forControlEvents: .TouchUpInside)
        button.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(44)
            make.height.equalTo(44)
            make.trailing.equalTo(-25)
            make.centerY.equalTo(container)
        }
        
        label.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(container).inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0))
        }
        
        return container
    }
    
    func addReview(sender: AnyObject?) {
        NSLog("add review")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        performSegueWithIdentifier("addReviewSegue", sender: sender)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "addReviewSegue" {
            guard let reviewViewController = segue.destinationViewController as? AddReviewTableViewController else { fatalError() }
            reviewViewController.info = self.info
        }
    }
    
    @IBOutlet weak var reviewsTable: UITableView! {
        didSet {
            reviewsTable.dataSource = self
            reviewsTable.delegate = self
        }
    }
    @IBOutlet weak var card: BurgerCard! {
        didSet {
            card.clipsToBounds = true
        }
    }
    
    var info: BurgerDetailInfo? {
        didSet {
            navigationItem.title = info?.burgerWrapper.name
            reloadView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reviewsTable.tableHeaderView = card
        reviewsTable.sectionHeaderHeight = 40
        card.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        reloadView()
    }
    
    func reloadView() {
        guard let info = self.info else { return }
        dispatch_async(dispatch_get_main_queue()) {
            [unowned self] in
            self.card?.setJoint(info.burgerWrapper)
            self.reviewsTable.reloadData()
            //            self.layoutHeaderView(self.reviewsTable.bounds.width, forTable: self.reviewsTable)
        }
    }
    
    func doneButtonHandler(sender: AnyObject?) {
        NSLog("presenting vc is \(self.presentingViewController)")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension BurgerDetailViewController: BurgerCardDelegate {
    func callHandler(sender: AnyObject?) {
        if let
        phoneString = self.info?.burgerWrapper.phone,
        phoneURL = NSURL(string: "tel:\(phoneString)") {
            UIApplication.sharedApplication().openURL(phoneURL)
        }
    }
    
    func websiteHandler(sender: AnyObject?) {
        if let
        websiteString = self.info?.burgerWrapper.website,
            websiteURL = NSURL(string: websiteString) {
                let safariViewController = SFSafariViewController(URL: websiteURL)
                navigationController?.pushViewController(safariViewController, animated: true)
        }
    }
    
    func directionsHandler(sender: AnyObject?) {
        // get a proper address dictionary for the destination
        if let
            destinationCoordinate = info?.burgerWrapper.coordinate {
                let origin = MKMapItem.mapItemForCurrentLocation()
                let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
                
                destination.name = info?.burgerWrapper.name
                
                MKMapItem.openMapsWithItems([origin, destination], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    func checkinHandler(sender: AnyObject?) {
    }
    
    func reviewHandler(sender: AnyObject?) {
    }
}

extension BurgerDetailViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return reviewsHeader
    }
}

extension BurgerDetailViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return info?.reviews.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ReviewCell", forIndexPath: indexPath)
        cell.textLabel?.text = "some review"
        return cell
    }
}
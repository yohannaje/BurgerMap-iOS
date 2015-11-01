//
//  BurgerDetailViewController.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 9/16/15.
//
//

import UIKit
import SnapKit

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

class BurgerCard: UIView {
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
    
    func setJoint(joint: BurgerWrapper) {
        nameLabel?.text = joint.name
        typeLabel?.text = "Joint"
        addressValueLabel?.text = joint.address
        phoneValueLabel?.text = joint.phone
        websiteValueLabel?.text = joint.website
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
        label.text = "\(info?.reviews.count ?? 0) reviews"
        label.backgroundColor = UIColor.clearColor()
        
        let container = UIView()
        container.backgroundColor = UIColor.burgerOrangeColor()
        container.addSubview(label)
        
        label.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(container).inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0))
        }
        
        return container
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

/*
extension BurgerDetailViewController {
    // This extension handles the dynamic table view header
    // by Marco Arment here https://gist.github.com/marcoarment/1105553afba6b4900c10
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        self.layoutHeaderView(size.width, forTable: reviewsTable)
    }
    
    func layoutHeaderView(width: CGFloat, forTable tableView: UITableView) {
        let view = reviewsHeader
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // [add subviews and their constraints to view]
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        let widthConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: width)
        
        view.addConstraint(widthConstraint)
        let height = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        view.removeConstraint(widthConstraint)
        
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        tableView.tableHeaderView = view
    }
}
*/

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
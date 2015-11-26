//
//  AddReviewTableViewController.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 11/25/15.
//
//

import UIKit
import CoreLocation
import Parse

class BurgerReview {
    
    static let WillStartSavingNotification = "BurgerReviewWillStartSaving"
    static let DidFinishSavingNotification = "BurgerReviewDidFinishSaving"
    
    let info: BurgerDetailInfo
    let user: PFUser
    var rating: Int = 3
    var content: String = ""
    
    init(info: BurgerDetailInfo, user: PFUser) {
        self.info = info
        self.user = user
    }
    
    func save() {
        let review = PFObject(className: "BusinessReview")
        review["content"] = content
        review["rating"] = rating
        review["business"] = info.burgerWrapper.id
        let relation = user.relationForKey("reviews")
        relation.addObject(review)
        
        NSNotificationCenter.defaultCenter().postNotificationName(BurgerReview.WillStartSavingNotification, object: self)
        user.saveInBackgroundWithBlock {
            [weak self](saved, error) -> Void in
            let sself = self
            
            let userInfo: [String : AnyObject] = {
                var d = [String : AnyObject]()
                if let error = error { d["error"] = error }
                d["result"] = saved
                return d
            }()
            
            let notification = NSNotification(name: BurgerReview.DidFinishSavingNotification, object: sself, userInfo: userInfo)
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
}

class AddReviewTableViewController: UITableViewController {
    var info: BurgerDetailInfo!
    var review: BurgerReview?
    
    @IBOutlet weak var reviewTextView: UITextView! {
        didSet {
            reviewTextView.delegate = self
        }
    }
    
    @IBOutlet weak var jointNameLabel: UILabel!
    @IBOutlet weak var jointDistanceLabel: UILabel!
    @IBOutlet weak var starRatingView: UIView!
    
    lazy var saveButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveReview:")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.burgerDarkGrayColor()
        navigationItem.rightBarButtonItem = saveButton
    }
    
    func saveReview(sender: AnyObject?) {
        NSLog("save review")
        review?.save()
    }
    
    func willStartSavingReview(notification: NSNotification) {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        aiv.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: aiv)
    }
    
    func didFinishSavingReview(notification: NSNotification) {
        navigationItem.rightBarButtonItem = saveButton
    }
    
    override func viewWillAppear(animated: Bool) {
        if let user = PFUser.currentUser() {
            review = BurgerReview(info: self.info, user: user)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "willStartSavingReview:", name: BurgerReview.WillStartSavingNotification, object: review)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFinishSavingReview:", name: BurgerReview.DidFinishSavingNotification, object: review)
        } else {
            fatalError("no user defined, cannot add review")
        }
        
        reviewTextView.becomeFirstResponder()
        
        
        jointNameLabel.text = info.burgerWrapper.name
        jointDistanceLabel.text = "Distance could not be determined"
        if CLLocationManager.authorizationStatus() != .Denied {
            let locationManager = CLLocationManager()
            let coordinate = info.burgerWrapper.coordinate
            if let distance = locationManager.location?.distanceFromLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) {
                jointDistanceLabel.text = String(format: "distance: %.2f", arguments: [distance])
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension AddReviewTableViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        review?.content = textView.text
    }
}

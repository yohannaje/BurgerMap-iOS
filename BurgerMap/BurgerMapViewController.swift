//
//  BurgerMapViewController.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 9/11/15.
//
//

import UIKit
import MapKit
import CoreLocation
import Parse
import ParseFacebookUtilsV4
import GoogleMaps

let ShowDetailSegueIdentifier = "ShowBurgerDetailSegue"

extension UIView {
    var snapshot: UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, 0.0);
        layer.renderInContext(UIGraphicsGetCurrentContext()!);
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}

func checkString(s: String?) -> Bool {
    guard let r = s where r.utf8.count > 0 else { return false }
    return true
}

func checkString(s: String?, _ t: String) -> String {
    if checkString(s) { return s! }
    return t
}

typealias JSONDictionary = [NSObject : AnyObject]

class BurgerWrapper: NSObject {
    private let raw: JSONDictionary
    
    init(_ dict: JSONDictionary) { raw = dict }
    
    var id: String { return "\(raw["id"] as? Int)" }
    var name: String { return raw["hamburgueseria"] as! String }
    var coordinate: CLLocationCoordinate2D {
        let lat = raw["lat"] as! CLLocationDegrees
        let lon = raw["lon"] as! CLLocationDegrees
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var fromGoogle: Bool { return raw["origin"] != nil }
    
    var rating: Int { return 3 }
    var address: String { return checkString(raw["direccion"] as? String, NSLocalizedString("No address", comment: "Joint no address found")) }
    var phone: String { return checkString(raw["telefono"] as? String, NSLocalizedString("No phone", comment: "Joint no phone found")) }
    var website: String? { return checkString(raw["web"] as? String, NSLocalizedString("No website", comment: "Joint no website found")) }
    
    var hasAddress: Bool { return checkString(raw["direccion"] as? String) }
    var hasPhone: Bool { return checkString(raw["telefono"] as? String) }
    var hasWebsite: Bool { return checkString(raw["web"] as? String) }
    
}

extension GooglePlacesResult {
    var asBurgerWrapper: BurgerWrapper? {
        let d: JSONDictionary = [
                "id": self.placeId,
                "hamburgueseria": self.name,
                "direccion": self.vicinity,
                "lat": self.coordinates.latitude,
                "lon": self.coordinates.longitude,
                "origin": "GOOGLE"
        ]
        return BurgerWrapper(d)
    }
}

extension BurgerWrapper: MKAnnotation {
    var title: String? { return name }
}

class LocationHelper: NSObject, CLLocationManagerDelegate {
    typealias AuthorizationStatusCallback = (CLAuthorizationStatus) -> (Void)
    
    static let instance = LocationHelper()
    static let locationManager = CLLocationManager()
    
    var authorizationCheckCompletionBlock: AuthorizationStatusCallback!
    var desiredAuthorizationStatus: CLAuthorizationStatus!
    
    
    class func checkLocationAuthorization(desiredAuthorizationStatus: CLAuthorizationStatus, block: AuthorizationStatusCallback) {
        if CLLocationManager.authorizationStatus() == desiredAuthorizationStatus {
            block(CLLocationManager.authorizationStatus())
            return
        } else {
            LocationHelper.instance.authorizationCheckCompletionBlock = block
            LocationHelper.instance.desiredAuthorizationStatus = desiredAuthorizationStatus
            LocationHelper.locationManager.delegate = LocationHelper.instance
            switch desiredAuthorizationStatus {
            case .AuthorizedAlways:
                locationManager.requestAlwaysAuthorization()
            case .AuthorizedWhenInUse:
                locationManager.requestWhenInUseAuthorization()
            default:
                break
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if let desiredAuthorizationStatus = desiredAuthorizationStatus, completionBlock = authorizationCheckCompletionBlock where status == desiredAuthorizationStatus {
            completionBlock(desiredAuthorizationStatus)
        }
    }
    
}

class BurgerMapViewController: UIViewController {
    
    lazy private var placesClient: GMSPlacesClient = {
        return GMSPlacesClient()
    }()
    
    lazy private var locationManager: CLLocationManager = {
        let lm = CLLocationManager()
        lm.delegate = self
        return lm
    }()
    
    lazy private var burgersList: [BurgerWrapper] = {
        guard let
            fileURL = NSBundle.mainBundle().URLForResource("Burgers", withExtension: "json"),
            stream = NSInputStream(URL: fileURL)
            else { return [] }
        
        do {
            stream.open()
            defer { stream.close() }
            guard let objects = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? [JSONDictionary] else { return [] }
            return objects.map { BurgerWrapper($0) }
        } catch {
            return []
        }
    }()
    
    @IBOutlet var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.userTrackingMode = MKUserTrackingMode.Follow
        }
    }
    
    @IBOutlet var menuBarButton: UIBarButtonItem!
    
    @IBOutlet weak var locationButton: UIButton!
    
    
    var oldCenter: CLLocationCoordinate2D?
    var firstLocate: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo"))
        
        navigationItem.leftBarButtonItem = {
            return UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: ContainerViewController.sharedInstance, action: "toggleMenu:")
            }()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"), style: .Plain, target: self, action: "showSearchViewController:")
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        ContainerViewController.sharedInstance.closeMenu()
    }
    
    override func viewWillAppear(animated: Bool) {
        LocationHelper.checkLocationAuthorization(.AuthorizedWhenInUse) {
            [unowned self] _ in
            NSLog("location authorized")
            self.locationManager.startUpdatingLocation()
            self.mapView.showsUserLocation = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        mapView.addAnnotations(burgersList)
        
        if !CLLocationCoordinate2DIsValid(mapView.userLocation.coordinate) {
            mapView.showAnnotations(burgersList, animated: true)
        }
        
        if PFUser.currentUser() == nil {
            PFFacebookUtils.logInInBackgroundWithReadPermissions(["user_about_me"]) {
                (user, error) -> Void in
                if (user == nil) {
                    NSLog("Uh oh. The user cancelled the Facebook login.");
                } else if (user!.isNew) {
                    NSLog("User signed up and logged in through Facebook!");
                } else {
                    NSLog("User logged in through Facebook!");
                }
            }
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowBurgerDetailSegue" {
            guard let
                vc = segue.destinationViewController as? BurgerDetailViewController,
                info = sender as? BurgerDetailInfo
                else { return }
            vc.info = info
        }
    }
    
    @IBAction func locationButtonTapped(sender: AnyObject?) {
        let mode: MKUserTrackingMode = mapView.userTrackingMode == .None ? .Follow : .None
        mapView.setUserTrackingMode(mode, animated: true)
    }
    
    @IBAction func unwindFromDetail(segue: UIStoryboardSegue!) {
        
    }
    
    func showSearchViewController(sender: AnyObject?) {
        
    }
}

extension BurgerMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        oldCenter = mapView.centerCoordinate
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard let oldCenter = oldCenter else { return }
        let old = CLLocation(coordinate: oldCenter)
        let new = CLLocation(coordinate: mapView.centerCoordinate)
        if true || new.distanceFromLocation(old) > 400 {
            self.oldCenter = new.coordinate
            GooglePlacesSearcher.sharedInstance.search(mapView.centerCoordinate) {
                (error, attrib, places) in
                guard
                let
                    places = places,
                    attrib = attrib
                where
                    error == nil
                else {
                    NSLog("error: \(error)")
                    return
                }
                
                let toRemove = mapView.annotations.filter {
                    (ann) -> Bool in
                    guard let ann = ann as? BurgerWrapper else { return false }
                    return ann.fromGoogle
                }
                
                NSLog("show attrib somewhere: \(attrib)")

                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    mapView.removeAnnotations(toRemove)
                    mapView.addAnnotations(places.flatMap { $0.asBurgerWrapper })
                })
            }
        }
    }
    
    func mapView(mapView: MKMapView, didChangeUserTrackingMode mode: MKUserTrackingMode, animated: Bool) {
        locationButton.selected = mode != .None
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if firstLocate {
            firstLocate = false
            if let coordinate = userLocation.location?.coordinate {
                let region = MKCoordinateRegionMakeWithDistance(coordinate, 3000, 3000)
                mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        guard let annotation = annotation as? BurgerWrapper else { fatalError("wtf kind of annotation we have here?!") }
        let view: MKAnnotationView
        if let v = mapView.dequeueReusableAnnotationViewWithIdentifier("BurgerPin") {
            view = v
        } else {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: "BurgerPin")
        }
        view.image = {
            if annotation.fromGoogle {
                return UIImage(named: "pin-google")
            }
            return UIImage(named: "pin")
        }()
        view.centerOffset = CGPoint(x: 0, y: -view.bounds.height)
        view.canShowCallout = true
        return view
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let wrapper = view.annotation as? BurgerWrapper else { return }
        let identifier = "ShowBurgerDetailSegue"
        let info = BurgerDetailInfo(headerImage: nil, burgerWrapper: wrapper)
        performSegueWithIdentifier(identifier, sender: info)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}

extension BurgerMapViewController: CLLocationManagerDelegate { }
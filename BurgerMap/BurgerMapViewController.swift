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

func checkString(s: String?, _ t: String) -> String {
    guard let r = s where r.utf8.count > 0 else { return t }
    return r
}

typealias JSONDictionary = [NSObject : AnyObject]

class BurgerWrapper: NSObject {
    private let raw: JSONDictionary
    
    init(_ dict: JSONDictionary) { raw = dict }
    
    var id: String { return raw["id"] as! String }
    var name: String { return raw["hamburgueseria"] as! String }
    var coordinate: CLLocationCoordinate2D {
        let lat = raw["lat"] as! CLLocationDegrees
        let lon = raw["lon"] as! CLLocationDegrees
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var rating: Int { return 3 }
    var address: String { return checkString(raw["direccion"] as? String, NSLocalizedString("No address", comment: "Joint no address found")) }
    var phone: String { return checkString(raw["telefono"] as? String, NSLocalizedString("No phone", comment: "Joint no phone found")) }
    var website: String? { return checkString(raw["web"] as? String, NSLocalizedString("No website", comment: "Joint no website found")) }
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
            navigationItem.rightBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        }
    }
    
    @IBOutlet var menuBarButton: UIBarButtonItem!
    
    var firstLocate: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = {
            return UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: ContainerViewController.sharedInstance, action: "toggleMenu:")
        }()
        
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
        mapView.showAnnotations(burgersList, animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowBurgerDetailSegue" {
            guard let
                vc = segue.destinationViewController as? BurgerDetailViewController else { return }
            vc.info = sender as? BurgerDetailInfo
        }
    }
    
    @IBAction func unwindFromDetail(segue: UIStoryboardSegue!) {
        
    }

}

extension BurgerMapViewController: MKMapViewDelegate {
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
        let view: MKAnnotationView
        if let v = mapView.dequeueReusableAnnotationViewWithIdentifier("BurgerPin") {
            view = v
        } else {
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: "BurgerPin")
        }
        view.image = UIImage(named: "pin")
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
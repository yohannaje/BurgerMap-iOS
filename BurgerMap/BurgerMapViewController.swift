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
import SWRevealViewController

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
    var phone: String { return raw["telefono"] as! String }
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
    
    override func viewWillAppear(animated: Bool) {
        LocationHelper.checkLocationAuthorization(.AuthorizedWhenInUse) {
            [unowned self] _ in
            NSLog("location authorized")
            self.locationManager.startUpdatingLocation()
            self.mapView.showsUserLocation = true
        }
        
        if let revealVC = revealViewController() {
            menuBarButton.target = revealVC
            menuBarButton.action = "revealToggle:"
            navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        } else {
            NSLog("No reveal VC found :-(")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if let revealVC = revealViewController() {
            navigationController?.navigationBar.removeGestureRecognizer(revealVC.panGestureRecognizer())
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        mapView.addAnnotations(burgersList)
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
        view.image = UIImage(named: "burger_stand")
        view.canShowCallout = true
        return view
    }
}

extension BurgerMapViewController: CLLocationManagerDelegate { }
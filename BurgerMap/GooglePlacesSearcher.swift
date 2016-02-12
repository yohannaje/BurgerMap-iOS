//
//  GooglePlacesSearcher.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 11/29/15.
//
//

import UIKit
import CoreLocation
import Foundation

struct GooglePlacesResult {
    let iconURL: NSURL
    let id: String
    let name: String
    let placeId: String
    let reference: String
    let vicinity: String
    let coordinates: CLLocationCoordinate2D
    
    static func buildResults(dict: JSONDictionary) -> (attributions: String, places: [GooglePlacesResult])? {
        guard
        let
            attributions = dict["html_attributions"] as? [String],
            status = dict["status"] as? String,
            resultsArray = dict["results"] as? [JSONDictionary]
        where
            status == "OK"
        else {
            NSLog(dict["status"] as! String)
            return nil
        }
        
        return (attributions: attributions.first ?? "Google Inc.", places: resultsArray.map { GooglePlacesResult(dictionary: $0) })
    }
    
    private static func getCoordinate(dict: JSONDictionary) -> CLLocationCoordinate2D? {
        guard let
            geo = dict["geometry"] as? JSONDictionary,
            loc = geo["location"] as? JSONDictionary,
            lat = loc["lat"] as? CLLocationDegrees,
            lng = loc["lng"] as? CLLocationDegrees
            else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    private init(dictionary: JSONDictionary) {
        guard let
            iconURLString = dictionary["icon"] as? String,
            iconURL = NSURL(string: iconURLString),
            id = dictionary["id"] as? String,
            name = dictionary["name"] as? String,
            placeId = dictionary["place_id"] as? String,
            coordinates = GooglePlacesResult.getCoordinate(dictionary),
            vicinity = dictionary["vicinity"] as? String
            else {
                fatalError("could not create GooglePlacesResult object")
        }
        
        self.iconURL = iconURL
        self.id = id
        self.name = name
        self.placeId = placeId
        self.coordinates = coordinates
        self.vicinity = vicinity
        self.reference = "LALALA"
    }
}

typealias GooglePlacesSearcherCallback = (error: ErrorType?, attributions: String?, places: [GooglePlacesResult]?) -> Void
class GooglePlacesSearcher: NSObject {
    static let sharedInstance = GooglePlacesSearcher()
    
    private static let apiKey = "AIzaSyBN6OY6naRYQfamDPvNMQMJsNSzyKZvjvI"
    private static var url: NSURL {
        let s = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        return NSURL(string: s)!
    }
    private static var inFlight = false
    
    func search(coordinates: CLLocationCoordinate2D, callback: GooglePlacesSearcherCallback) {
        if GooglePlacesSearcher.inFlight { return }
        if !CLLocationCoordinate2DIsValid(coordinates) { return }
        GooglePlacesSearcher.inFlight = true
        let params: [String : String] = [
            "key" : GooglePlacesSearcher.apiKey,
            "location": String(format: "%f,%f", arguments: [coordinates.latitude, coordinates.longitude]),
            //            "radius": String(format: "%d", arguments: [5000]),
            "rankby": "distance",
            "types": "food|meal_delivery|restaurant|meal_takeaway",
            "keyword": "burger|hamburgueseria"
        ]
        
        let components = NSURLComponents(URL: GooglePlacesSearcher.url, resolvingAgainstBaseURL: false)
        components?.queryItems = params.map { NSURLQueryItem(name: $0, value: $1) }
        guard let url = components?.URL else { fatalError("🔴 Could not create URL :-(") }
        NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) -> Void in
            defer { GooglePlacesSearcher.inFlight = false }
            guard let
                data = data,
                response = response as? NSHTTPURLResponse
            where
                error == nil
            else {
                callback(error: error, attributions: nil, places: nil)
                return
            }
            
            NSLog("response: \(response.statusCode)")
            
            
            guard
                let
                object = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as? JSONDictionary,
                r = GooglePlacesResult.buildResults(object) else {
                callback(
                    error: NSError(domain: "GooglePlacesSearcher", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Could not build results"]),
                    attributions: nil,
                    places: nil)
                return
            }
            callback(error: nil, attributions: r.attributions, places: r.places)
        }.resume()
        NSLog("LA CONCHA DE TU MADRE, ALLBOYS")
        
    }
}

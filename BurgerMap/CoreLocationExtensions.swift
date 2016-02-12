//
//  CoreLocationExtensions.swift
//  BurgerMap
//
//  Created by Nicolas Ameghino on 11/29/15.
//
//

import Foundation
import CoreLocation

extension CLLocation {
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

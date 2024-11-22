//
//  CLLocationExtension.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 10/19/24.
//

import CoreLocation


extension CLLocation {
    // Parameter toLocation: The destination CLLocation.
    // Returns: Distance in miles.
    func distanceInMiles(to toLocation: CLLocation) -> Double {
        return self.distance(from: toLocation) * 0.000621371
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

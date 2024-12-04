//
//  BathroomMark.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 10/19/24.
//


import SwiftData
import MapKit

@Model
class BathroomMark: Identifiable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var bathrooms: Bathrooms?
    // var averageRating: Double
    
    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

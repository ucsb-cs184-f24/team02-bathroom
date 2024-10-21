//
//  Bathrooms.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 10/19/24.
//

import SwiftData
import MapKit

@Model
class Bathrooms: Identifiable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double?
    var longitude: Double?
    var latitudeDelta: Double?
    var longitudeDelta: Double?
    
    @Relationship(deleteRule: .cascade)
    var placemarks: [BathroomMark] = []
    
    init(name: String, latitude: Double? = nil, longitude: Double? = nil, latitudeDelta: Double? = nil, longitudeDelta: Double? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
    
    var region: MKCoordinateRegion? {
        if let latitude, let longitude, let latitudeDelta, let longitudeDelta {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        } else {
            return nil
        }
    }
}

extension Bathrooms {
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: Bathrooms.self,
            BathroomMark.self,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: true
            )
        )
        
        let ucsb = Bathrooms(
            name: "UCSB",
            latitude: 34.41332,
            longitude: -119.84555,
            latitudeDelta: 0.015,
            longitudeDelta: 0.015
        )
        
        container.mainContext.insert(ucsb)
        
        let placeMarks: [BathroomMark] = [
            BathroomMark(name: "testing location", latitude: 34.13556, longitude: -118.02218),
            BathroomMark(name: "USC Arcadia Hospital", latitude: 34.13415, longitude: -118.04146),
            BathroomMark(name: "testing location 2", latitude: 34.13610, longitude: -118.02225),
            BathroomMark(name: "ilp 1st floor", latitude: 34.41245, longitude: -119.84572),
            BathroomMark(name: "phelp 1st floor", latitude: 34.41632, longitude: -119.84458),
            BathroomMark(name: "iv theater", latitude: 34.41135, longitude: -119.85497),
            BathroomMark(name: "testing - Lan Noodles", latitude: 34.14049, longitude: -118.02126)
        ]
        
        placeMarks.forEach { placemark in
            ucsb.placemarks.append(placemark)
        }
        
        return container
    }
}

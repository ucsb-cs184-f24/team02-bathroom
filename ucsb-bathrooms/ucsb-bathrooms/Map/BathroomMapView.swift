//
//  MainMap.swift
//  ucsb-bathrooms
//
//  Created by Zheli Chen on 10/19/24.
//

import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct BathroomMapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Query private var listBathroom: [BathroomMark]
    
    // state variables for toggle functionality
    @State private var showNearby = false
    @State private var nearbyBathrooms: [BathroomMark] = []
    
    // state variable for no bathroom alert
    @State private var showingNoBathroomsAlert = false

    
    var body: some View {
        ZStack(alignment: .topLeading) { // Changed from .topTrailing to .topLeading
            Map(position: $cameraPosition) {
                UserAnnotation()
                
                // Display filtered or all bathrooms based on `showNearby`
                ForEach(showNearby ? nearbyBathrooms : listBathroom) { placemark in
                    Marker(coordinate: placemark.coordinate) {
                        /*
                        // styled reserved for best bathrooms use only
                        Label(placemark.name, systemImage: "star.fill")
                        */
                    }
                    // color reserved for best bathroom nearby/all view mode
                    //.tint(.yellow)
                }
            }
            .onAppear {
                updateCameraPosition()
            }
            .onChange(of: locationManager.userLocation) { _, _ in
                if showNearby {
                    filternearbyBathrooms()
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            
            // toggle button
            // show all/nearby bathrooms only
            Button(action: {
                showNearby.toggle()
                if showNearby {
                    filternearbyBathrooms()
                }
            }) {
                HStack {
                    Image(systemName: showNearby ? "location.fill" : "location")
                    Text(showNearby ? "Show All Restrooms" : "Show Nearby Restrooms")
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .foregroundColor(.blue)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
            .padding([.leading, .top], 16)
        }
        // alert if no bathrooms is nearby within 0.2 miles
        .alert("No Nearby Restrooms", isPresented: $showingNoBathroomsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No nearby restrooms found within 0.2 miles. or perhaps the location permission is not granted to this app.")
        }
    }
    
    func updateCameraPosition() {
        if let userLocation = locationManager.userLocation {
            let userRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.15,
                    longitudeDelta: 0.15
                )
            )
            withAnimation {
                cameraPosition = .region(userRegion)
            }
        }
    }
    
    // filters bathrooms within 0.2 miles from the user's current location.
    func filternearbyBathrooms() {
        guard let userLocation = locationManager.userLocation else {
            nearbyBathrooms = []
            showingNoBathroomsAlert = false
            return
        }
        
        let userCLLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        nearbyBathrooms = listBathroom.filter { placemark in
            let placemarkCLLocation = CLLocation(latitude: placemark.latitude, longitude: placemark.longitude)
            return userCLLocation.distanceInMiles(to: placemarkCLLocation) <= 0.2
        }
        
        if nearbyBathrooms.isEmpty {
            // toggle the alert
            showingNoBathroomsAlert = true
        }
    }
}



#Preview {
    BathroomMapView()
        .modelContainer(Bathrooms.preview)
}

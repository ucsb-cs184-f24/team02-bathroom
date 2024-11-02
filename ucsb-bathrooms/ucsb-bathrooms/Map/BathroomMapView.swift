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
    
    @State private var showNearby = false
    @State private var nearbyBathrooms: [BathroomMark] = []
    @State private var showingNoBathroomsAlert = false
    @State private var selectedBathroom: BathroomMark?
    @State private var isNavigatingToDetail = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Map(position: $cameraPosition, selection: $selectedBathroom) {
                    UserAnnotation()
                    
                    ForEach(showNearby ? nearbyBathrooms : listBathroom) { placemark in
                        Marker(placemark.name, coordinate: placemark.coordinate)
                            .tag(placemark)
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
                
                VStack {
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
                    
                    Spacer()
                }
            }
            .alert("No Nearby Restrooms", isPresented: $showingNoBathroomsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("No nearby restrooms found within 0.2 miles. or perhaps the location permission is not granted to this app.")
            }
            .onChange(of: selectedBathroom) { oldValue, newValue in
                if let newValue {
                    print("Selected bathroom: \(newValue.name)")
                    isNavigatingToDetail = true
                }
            }
            .navigationDestination(isPresented: $isNavigatingToDetail) {
                if let selectedBathroom {
                    //BathroomDetailView(bathroomId: selectedBathroom.id)
                    BathroomDetailView(bathroomID: "ILP 1st Floor", location: "Building ILP, 1st Floor", gender: "Unisex")
                }
            }
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


struct CustomMarkerView: View {
    var isSelected: Bool
    
    var body: some View {
        Image(systemName: "toilet")
            .foregroundColor(isSelected ? .red : .blue)
            .background(
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
            )
    }
}


#Preview {
    BathroomMapView()
        .modelContainer(Bathrooms.preview)
}

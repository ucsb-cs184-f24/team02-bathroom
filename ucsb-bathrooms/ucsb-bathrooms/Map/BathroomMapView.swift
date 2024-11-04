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
    @State private var bathrooms: [FirestoreManager.Bathroom] = []
    @State private var selectedBathroom: FirestoreManager.Bathroom?
    @State private var isNavigatingToDetail = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Map(position: $cameraPosition,
                    selection: $selectedBathroom) {
                    UserAnnotation()

                    ForEach(bathrooms) { bathroom in
                        Annotation(bathroom.name,
                                 coordinate: CLLocationCoordinate2D(
                                    latitude: bathroom.location.latitude,
                                    longitude: bathroom.location.longitude
                                 ),
                                 anchor: .bottom) {
                            Image(systemName: "toilet")
                                .padding(8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .tag(bathroom)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }

                if let selectedBathroom {
                    VStack {
                        NavigationLink(
                            destination: BathroomDetailView(
                                bathroomID: selectedBathroom.id,
                                location: selectedBathroom.name,
                                gender: selectedBathroom.gender
                            ),
                            isActive: $isNavigatingToDetail
                        ) {
                            EmptyView()
                        }

                        Button {
                            isNavigatingToDetail = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(selectedBathroom.name)
                                    .font(.headline)

                                HStack {
                                    // Rating Stars
                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= Int(selectedBathroom.averageRating) ? "star.fill" : "star")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 12))
                                        }
                                    }

                                    Text(String(format: "%.1f", selectedBathroom.averageRating))
                                        .font(.subheadline)

                                    Text("(\(selectedBathroom.totalReviews) reviews)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Text("Tap to view details")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
        }
        .task {
            await loadBathrooms()
        }
    }

    func loadBathrooms() async {
        do {
            bathrooms = try await FirestoreManager.shared.getAllBathrooms()
        } catch {
            print("Error loading bathrooms: \(error)")
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

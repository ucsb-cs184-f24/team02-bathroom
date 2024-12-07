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
    @State private var worstBathroomIDs: Set<String> = []
    @State private var bestBathroomIDs: Set<String> = []
    @StateObject private var locationManager = LocationManager()
    @State private var bathrooms: [FirestoreManager.Bathroom] = []
    @State private var selectedBathroom: FirestoreManager.Bathroom?
    @State private var isNavigatingToDetail = false
    @State private var isNavigatingToAddBathroom = false
    @State private var showingLocationErrorAlert = false
    @State private var initialLocation: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 34.4140,
            longitude: -119.8489
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.01,
            longitudeDelta: 0.01
        )
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer
                .zIndex(0)

            locationButton
                .zIndex(1)

            if let bathroom = selectedBathroom {
                BathroomPreviewCard(
                    bathroom: bathroom,
                    isNavigatingToDetail: $isNavigatingToDetail
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .bottom)
                    )
                )
                .zIndex(2)
            }
            //.bottomTrailing
            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    NavigationLink(
                                        destination: AddBathroomView(
                                            initialLocation: locationManager.userLocation?.coordinate ?? region.center
                                        ),
                                        isActive: $isNavigatingToAddBathroom
                                    ) {
                                        Button {
                                            isNavigatingToAddBathroom = true
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                                .padding()
                                                .background(Color("bg1"))
                                                .clipShape(Circle())
                                                .shadow(radius: 1.5)
                                        }
                                    }
                                    .padding()
                                }
                            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedBathroom)
        .task {
            await loadBathrooms()
        }
    }

    // MARK: - View Components

    private var mapLayer: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: bathrooms
        ) { bathroom in
            MapAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: bathroom.location.latitude,
                    longitude: bathroom.location.longitude
                )
            ) {
                BathroomMarker(
                    isSelected: selectedBathroom?.id == bathroom.id,
                    isWorstBathroom: worstBathroomIDs.contains(bathroom.id),
                    isBestBathroom: bestBathroomIDs.contains(bathroom.id),
                    isFavorited: false
                ) {
                    withAnimation {
                        selectedBathroom = bathroom
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Only dismiss if tapping the map, not a marker
                    if selectedBathroom != nil {
                        withAnimation {
                            selectedBathroom = nil
                        }
                    }
                }
        )
    }

    private var locationButton: some View {
        VStack {
            Button(action: centerOnUser) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(locationManager.authorizationStatus == .authorizedWhenInUse ? Color("accent") : .gray)
                    .padding(10)
                    .background(Color("bg1"))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private var selectedBathroomPreview: some View {
        if let bathroom = selectedBathroom {
            BathroomPreviewCard(
                bathroom: bathroom,
                isNavigatingToDetail: $isNavigatingToDetail
            )
            .transition(.move(edge: .bottom))
        }
    }

    // MARK: - Helper Functions

    private func centerOnUser() {
        locationManager.requestLocationIfNeeded()
        if let location = locationManager.userLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.01,
                        longitudeDelta: 0.01
                    )
                )
            }
        }
    }

    private func loadBathrooms() async {
        do {
            bathrooms = try await FirestoreManager.shared.getAllBathrooms()
            if let minRating = bathrooms.map({ $0.averageRating }).min() {
                        worstBathroomIDs = Set(
                            bathrooms
                                .filter { $0.averageRating == minRating }
                                .map { $0.id }
                        )
            }
            if let maxRating = bathrooms.map({ $0.averageRating }).max() {
                        bestBathroomIDs = Set(
                            bathrooms
                                .filter { $0.averageRating == maxRating }
                                .map { $0.id }
                        )
                //print("Best Bathroom IDs: \(bestBathroomIDs)")
            }
        } catch {
            print("Error loading bathrooms: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct BathroomMarker: View {
    let isSelected: Bool
    let isWorstBathroom: Bool
    let isBestBathroom: Bool
    let isFavorited: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorited ? "toilet.circle.fill" : "toilet.circle")
                .font(.system(size: 28))
                .foregroundColor(markerColor)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .opacity(isFavorited ? 1 : 0)
                        .offset(x: 8, y: -8)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var markerColor: Color {
        if isBestBathroom {
            return Color.green
                .adjustBrightness(-0.2)
                .adjustSaturation(-0.33)
        } else if isWorstBathroom {
            return Color.red
                        .adjustBrightness(-0.2)
                        .adjustSaturation(-0.2)
        } else {
            return Color("accent").adjustBrightness(+0.65).adjustBrightness(+1)
        }
    }
}

struct BathroomPreviewCard: View {
    let bathroom: FirestoreManager.Bathroom
    @Binding var isNavigatingToDetail: Bool

    var body: some View {
        VStack {
            NavigationLink(
                destination: BathroomDetailView(
                    bathroomID: bathroom.id,
                    location: bathroom.name,
                    gender: bathroom.gender
                ),
                isActive: $isNavigatingToDetail
            ) {
                EmptyView()
            }

            Button {
                isNavigatingToDetail = true
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(bathroom.name)
                            .font(.headline)
                            .foregroundColor(Color("accent"))

                        Spacer()

                        Label(bathroom.gender, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundColor(Color("accent"))
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            RatingStars(rating: bathroom.averageRating, starSize: 12)
                            Text(String(format: "%.1f", bathroom.averageRating))
                                .font(.subheadline)
                        }

                        Text("•")
                            .foregroundColor(.gray)

                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                            
                            Text("\(bathroom.totalUses) visits")
                                .font(.subheadline)
                            
                        }.foregroundColor(Color("accent"))

                        Spacer()

                        Text("View Details")
                            .font(.subheadline)
                            .foregroundColor(Color("accent"))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(
                                Color("accent")
                            )
                    }
                }
            }
            .padding()
            .background(Color("bg1"))
            .cornerRadius(15)
            .shadow(radius: 3)
        }
        .padding(.horizontal)
        .padding(.bottom, 49)
        .background(
            Color.clear
        )
    }
}

#Preview {
    BathroomMapView()
        .modelContainer(Bathrooms.preview)
}

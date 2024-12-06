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
    @State private var bathroomGroups: [BathroomGroup] = []
    @State private var selectedBathroom: FirestoreManager.Bathroom?
    @State private var selectedBathroomGroup: BathroomGroup?
    @State private var isNavigatingToDetail = false
    @State private var isNavigatingToAddBathroom = false

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
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .bottom)
                ))
                .zIndex(2)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    NavigationLink(
                        destination: AddBathroomView(
                            initialLocation: locationManager.userLocation?.coordinate ?? region.center,
                            onBathroomAdded: {
                                Task {
                                    await reloadBathrooms()
                                }
                            }
                        ),
                        isActive: $isNavigatingToAddBathroom
                    ) {
                        Button {
                            isNavigatingToAddBathroom = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 1.5)
                        }
                    }
                    .padding()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedBathroom)
        .sheet(item: $selectedBathroomGroup) { group in
            BathroomListSheet(bathrooms: group.bathrooms) { bathroom in
                selectedBathroom = bathroom
                selectedBathroomGroup = nil
            }
        }
        .task {
            await loadBathrooms()
            bathroomGroups = groupBathrooms(bathrooms)
        }
    }

    // MARK: - Map Layer

    private var mapLayer: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: bathroomGroups
        ) { group in
            MapAnnotation(coordinate: group.coordinate) {
                Button(action: {
                    if group.bathrooms.count == 1 {
                        // Single bathroom, select it
                        withAnimation {
                            selectedBathroom = group.bathrooms.first
                        }
                    } else {
                        // Multiple bathrooms at this location, show list
                        selectedBathroomGroup = group
                    }
                }) {
                    Image(systemName: group.bathrooms.count == 1 ? "toilet.circle" : "toilet.circle.fill")
                        .font(.system(size: 27))
                        .foregroundColor(markerColor(for: group))
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Dismiss preview if tapping outside a marker
                    if selectedBathroom != nil {
                        withAnimation {
                            selectedBathroom = nil
                        }
                    }
                }
        )
    }

    // MARK: - Location Button

    private var locationButton: some View {
        VStack {
            Button(action: centerOnUser) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundColor(locationManager.authorizationStatus == .authorizedWhenInUse ? .blue : .gray)
                    .padding(10)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
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
            updateBestAndWorstSets()
            bathroomGroups = groupBathrooms(bathrooms)
        } catch {
            print("Error loading bathrooms: \(error)")
        }
    }

    private func reloadBathrooms() async {
        do {
            bathrooms = try await FirestoreManager.shared.getAllBathrooms()
            updateBestAndWorstSets()
            bathroomGroups = groupBathrooms(bathrooms)
        } catch {
            print("Error reloading bathrooms: \(error)")
        }
    }

    private func updateBestAndWorstSets() {
        if let minRating = bathrooms.map({ $0.averageRating }).min() {
            worstBathroomIDs = Set(
                bathrooms.filter { $0.averageRating == minRating }.map { $0.id }
            )
        }
        if let maxRating = bathrooms.map({ $0.averageRating }).max() {
            bestBathroomIDs = Set(
                bathrooms.filter { $0.averageRating == maxRating }.map { $0.id }
            )
        }
    }

    private func groupBathrooms(_ bathrooms: [FirestoreManager.Bathroom]) -> [BathroomGroup] {
        var groups: [BathroomGroup] = []
        let threshold: CLLocationDistance = 25 // Adjust as needed

        for bathroom in bathrooms {
            if let index = groups.firstIndex(where: { $0.isClose(to: bathroom, threshold: threshold) }) {
                groups[index].bathrooms.append(bathroom)
            } else {
                let group = BathroomGroup(
                    coordinate: CLLocationCoordinate2D(
                        latitude: bathroom.location.latitude,
                        longitude: bathroom.location.longitude
                    ),
                    bathrooms: [bathroom]
                )
                groups.append(group)
            }
        }
        return groups
    }

    private func markerColor(for group: BathroomGroup) -> Color {
        let hasBestBathroom = group.bathrooms.contains { bestBathroomIDs.contains($0.id) }
        let hasWorstBathroom = group.bathrooms.contains { worstBathroomIDs.contains($0.id) }

        if group.bathrooms.count == 1 {
            let bathroom = group.bathrooms.first!
            if bestBathroomIDs.contains(bathroom.id) {
                return .green.adjustBrightness(-0.06).adjustSaturation(0.1)
            } else if worstBathroomIDs.contains(bathroom.id) {
                return .red.adjustBrightness(-0.07).adjustSaturation(-0.1)
            } else {
                return .blue.adjustBrightness(-0.06).adjustSaturation(-0.1)
            }
        } else {
            // For clusters with multiple bathrooms
            if hasBestBathroom {
                return .green.adjustBrightness(-0.06).adjustSaturation(0.1)
            } else if hasWorstBathroom {
                return .red.adjustBrightness(-0.07).adjustSaturation(-0.1)
            } else {
                return .purple.adjustBrightness(-0.05).adjustSaturation(-0.1)
            }
        }
    }
}

// MARK: - BathroomGroup Model

struct BathroomGroup: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    var bathrooms: [FirestoreManager.Bathroom]

    func isClose(to bathroom: FirestoreManager.Bathroom, threshold: CLLocationDistance) -> Bool {
        let groupLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let bathroomLocation = CLLocation(latitude: bathroom.location.latitude, longitude: bathroom.location.longitude)
        let distance = groupLocation.distance(from: bathroomLocation)
        return distance < threshold
    }
}

// MARK: - Supporting Views

struct BathroomListSheet: View {
    let bathrooms: [FirestoreManager.Bathroom]
    let onSelect: (FirestoreManager.Bathroom) -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(bathrooms) { bathroom in
                Button(action: {
                    onSelect(bathroom)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(bathroom.name)
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f ★", bathroom.averageRating))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Select a Bathroom")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
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

                        Spacer()

                        Label(bathroom.gender, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
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
                                .foregroundColor(.blue)
                            Text("\(bathroom.totalUses) visits")
                                .font(.subheadline)
                        }

                        Spacer()

                        Text("View Details")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 3)
        }
        .padding(.horizontal)
        .padding(.bottom, 49)
        .background(Color.clear)
    }
}

#Preview {
    BathroomMapView()
        .modelContainer(Bathrooms.preview)
}

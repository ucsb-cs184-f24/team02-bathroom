//
//  Leaderboard.swift
//  ucsb-bathrooms
//
//  Created by Megumi Ondo on 10/28/24.
//

import SwiftUI
import CoreLocation

// Model representing each bathroom
struct Bathroom: Identifiable {
    let id = UUID()
    let name: String
    let averageRating: Double
    let reviewCount: Int
}

// Sample data of bathrooms
let sampleBathrooms = [
    Bathroom(name: "ILP Second Floor", averageRating: 4.5, reviewCount: 120),
    Bathroom(name: "Elings Hall", averageRating: 4.2, reviewCount: 90),
    Bathroom(name: "Harold Frank Hall First Floor", averageRating: 4.3, reviewCount: 75),
    Bathroom(name: "SRB Second Floor", averageRating: 4.0, reviewCount: 110),
    Bathroom(name: "HSSB First Floor", averageRating: 3.8, reviewCount: 50)
]

// Model representing each bathroom review
struct BathroomReview: Identifiable {
    let id = UUID()
    let bathroomName: String
    let reviewerName: String
    let timestamp: Date
    let text: String
}

// Sample data of recent reviews
let sampleReviews = [
    BathroomReview(bathroomName: "ILP Second Floor", reviewerName: "Alice", timestamp: Date().addingTimeInterval(-3600), text: "Clean and spacious!"),
    BathroomReview(bathroomName: "Elings Hall", reviewerName: "Bob", timestamp: Date().addingTimeInterval(-7200), text: "Pretty good, but could use more soap."),
    BathroomReview(bathroomName: "Harold Frank Hall First Floor", reviewerName: "Charlie", timestamp: Date().addingTimeInterval(-10800), text: "Well-maintained and fresh-smelling."),
    BathroomReview(bathroomName: "SRB Second Floor", reviewerName: "David", timestamp: Date().addingTimeInterval(-14400), text: "A bit crowded during peak hours."),
    BathroomReview(bathroomName: "HSSB First Floor", reviewerName: "Eve", timestamp: Date().addingTimeInterval(-18000), text: "Decent, but sometimes out of paper towels.")
]

// View to display stars based on rating
struct StarRatingView: View {
    let rating: Double
    private let maxRating = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                    .foregroundColor(star <= Int(rating.rounded()) ? .yellow : .gray)
            }
        }
    }
}

// Leaderboard View for the bathrooms
struct BathroomLeaderboardView: View {
    @State private var bathrooms: [FirestoreManager.Bathroom] = []
    @StateObject private var locationManager = LocationManager()

    var topRatedBathrooms: [FirestoreManager.Bathroom] {
        bathrooms.sorted { $0.averageRating > $1.averageRating }
            .prefix(5)
            .map { $0 }
    }

    var nearbyBathrooms: [FirestoreManager.Bathroom] {
        guard let userLocation = locationManager.userLocation else {
            return bathrooms
        }

        return bathrooms.sorted { bathroom1, bathroom2 in
            let location1 = CLLocation(
                latitude: bathroom1.location.latitude,
                longitude: bathroom1.location.longitude
            )
            let location2 = CLLocation(
                latitude: bathroom2.location.latitude,
                longitude: bathroom2.location.longitude
            )
            return location1.distance(from: userLocation) < location2.distance(from: userLocation)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Top Rated Section
                    VStack(alignment: .leading) {
                        Text("Top Rated Bathrooms")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(topRatedBathrooms) { bathroom in
                                    NavigationLink(destination: BathroomDetailView(
                                        bathroomID: bathroom.id,
                                        location: bathroom.name,
                                        gender: bathroom.gender
                                    )) {
                                        TopRatedBathroomCard(bathroom: bathroom)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Divider()
                        .padding(.horizontal)

                    // Nearby Section
                    VStack(alignment: .leading) {
                        Text("Bathrooms Near You")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        ForEach(nearbyBathrooms) { bathroom in
                            NavigationLink(destination: BathroomDetailView(
                                bathroomID: bathroom.id,
                                location: bathroom.name,
                                gender: bathroom.gender
                            )) {
                                NearbyBathroomRow(
                                    bathroom: bathroom,
                                    userLocation: locationManager.userLocation
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
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

// Top Rated Bathroom Card
struct TopRatedBathroomCard: View {
    let bathroom: FirestoreManager.Bathroom

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Bathroom Icon
            Image(systemName: "toilet")
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)

            // Bathroom Info
            VStack(alignment: .leading, spacing: 4) {
                Text(bathroom.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Rating Stars
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(bathroom.averageRating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                }

                Text("\(bathroom.totalReviews) reviews")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 160, height: 160)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// Nearby Bathroom Row
struct NearbyBathroomRow: View {
    let bathroom: FirestoreManager.Bathroom
    let userLocation: CLLocation?

    private var distance: String {
        guard let userLocation = userLocation else { return "N/A" }

        let bathroomLocation = CLLocation(
            latitude: bathroom.location.latitude,
            longitude: bathroom.location.longitude
        )

        let distanceInMeters = userLocation.distance(from: bathroomLocation)
        if distanceInMeters < 1000 {
            return String(format: "%.0f m", distanceInMeters)
        } else {
            return String(format: "%.1f km", distanceInMeters / 1000)
        }
    }

    var body: some View {
        HStack(spacing: 15) {
            // Bathroom Icon
            Image(systemName: "toilet")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            // Bathroom Info
            VStack(alignment: .leading, spacing: 4) {
                Text(bathroom.name)
                    .font(.headline)

                HStack {
                    // Rating
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", bathroom.averageRating))
                            .font(.subheadline)
                    }

                    Text("•")
                        .foregroundColor(.gray)

                    // Distance
                    Text(distance)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Navigation Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// Main Content View
struct BathroomLeaderboardContentView: View {
    var body: some View {
        BathroomLeaderboardView()
    }
}

// Preview for testing
struct BathroomLeaderboardContentView_Previews: PreviewProvider {
    static var previews: some View {
        BathroomLeaderboardContentView()
    }
}


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
struct Leaderboard: View {
    @StateObject private var locationManager = LocationManager()
    @State private var topRatedBathrooms: [FirestoreManager.Bathroom] = []
    @State private var mostUsedBathrooms: [FirestoreManager.Bathroom] = []
    @State private var nearestBathrooms: [FirestoreManager.Bathroom] = []
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                tabBar

                Divider()
                    .padding(.top, 8)

                bathroomList
            }
            .navigationTitle("Leaderboard")
            .task {
                await loadBathrooms()
            }
        }
    }

    // MARK: - View Components

    private var tabBar: some View {
        HStack(spacing: 24) {
            TabButton(
                title: "Top Rated",
                icon: "star.fill",
                isSelected: selectedTab == 0
            ) {
                withAnimation { selectedTab = 0 }
            }

            TabButton(
                title: "Most Used",
                icon: "person.3.fill",
                isSelected: selectedTab == 1
            ) {
                withAnimation { selectedTab = 1 }
            }

            TabButton(
                title: "Nearest",
                icon: "location.fill",
                isSelected: selectedTab == 2
            ) {
                withAnimation {
                    selectedTab = 2
                    sortNearestBathrooms()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var bathroomList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(getCurrentList()) { bathroom in
                    bathroomLink(for: bathroom)
                }
            }
            .padding()
        }
    }

    private func bathroomLink(for bathroom: FirestoreManager.Bathroom) -> some View {
        NavigationLink(
            destination: BathroomDetailView(
                bathroomID: bathroom.id,
                location: bathroom.name,
                gender: bathroom.gender
            )
        ) {
            if selectedTab == 2 {
                NearestBathroomCard(
                    bathroom: bathroom,
                    distance: getDistance(to: bathroom)
                )
            } else {
                BathroomCard(
                    bathroom: bathroom,
                    rank: getRank(for: bathroom),
                    distance: nil
                )
            }
        }
    }

    // MARK: - Helper Functions

    private func getCurrentList() -> [FirestoreManager.Bathroom] {
        switch selectedTab {
        case 0: return topRatedBathrooms
        case 1: return mostUsedBathrooms
        case 2: return nearestBathrooms
        default: return []
        }
    }

    private func getRank(for bathroom: FirestoreManager.Bathroom) -> Int {
        let list = getCurrentList()
        return list.firstIndex(of: bathroom)! + 1
    }

    private func sortNearestBathrooms() {
        guard let userLocation = locationManager.userLocation else { return }

        nearestBathrooms.sort { b1, b2 in
            let location1 = CLLocation(latitude: b1.location.latitude, longitude: b1.location.longitude)
            let location2 = CLLocation(latitude: b2.location.latitude, longitude: b2.location.longitude)
            return location1.distance(from: userLocation) < location2.distance(from: userLocation)
        }
    }

    private func getDistance(to bathroom: FirestoreManager.Bathroom) -> Double? {
        guard let userLocation = locationManager.userLocation else { return nil }
        let bathroomLocation = CLLocation(
            latitude: bathroom.location.latitude,
            longitude: bathroom.location.longitude
        )
        return userLocation.distance(from: bathroomLocation)
    }

    private func loadBathrooms() async {
        do {
            let bathrooms = try await FirestoreManager.shared.getAllBathrooms()

            // Sort for top rated (minimum 3 reviews)
            topRatedBathrooms = bathrooms
                .filter { $0.totalReviews >= 3 }
                .sorted { $0.averageRating > $1.averageRating }
                .prefix(10)
                .map { $0 }

            // Sort for most used
            mostUsedBathrooms = bathrooms
                .sorted { $0.totalUses > $1.totalUses }
                .prefix(10)
                .map { $0 }

            // Initialize nearest bathrooms with all bathrooms
            nearestBathrooms = bathrooms
            sortNearestBathrooms()
        } catch {
            print("Error loading bathrooms: \(error)")
        }
    }
}

// Updated TabButton with icon
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.subheadline)
                    Text(title)
                        .font(.subheadline.bold())
                }
                .foregroundColor(isSelected ? .blue : .gray)

                // Indicator line
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// Updated BathroomCard
struct BathroomCard: View {
    let bathroom: FirestoreManager.Bathroom
    let rank: Int
    let distance: Double?

    init(bathroom: FirestoreManager.Bathroom, rank: Int, distance: Double? = nil) {
        self.bathroom = bathroom
        self.rank = rank
        self.distance = distance
    }

    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(getRankColor(rank: rank))
                    .frame(width: 36, height: 36)

                Text("\(rank)")
                    .font(.callout.bold())
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Title row
                HStack(alignment: .center) {
                    Text(bathroom.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Label(bathroom.gender, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                // Stats row
                HStack(spacing: 16) {
                    // Rating
                    HStack(spacing: 4) {
                        RatingStars(rating: bathroom.averageRating, starSize: 12)
                        Text(String(format: "%.1f", bathroom.averageRating))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("(\(bathroom.totalReviews))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Usage count
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                        Text("\(bathroom.totalUses)")
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }

    private func getRankColor(rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return Color.brown
        default: return .blue.opacity(0.8)
        }
    }

    private func formatDistance(meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            let kilometers = meters / 1000
            return String(format: "%.1fkm", kilometers)
        }
    }
}

// New card design for nearest bathrooms
struct NearestBathroomCard: View {
    let bathroom: FirestoreManager.Bathroom
    let distance: Double?

    var body: some View {
        HStack(spacing: 16) {
            // Bathroom icon
            Image(systemName: "toilet.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 8) {
                // Title row
                HStack(alignment: .center) {
                    Text(bathroom.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if let distance = distance {
                        Text(formatDistance(meters: distance))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    Label(bathroom.gender, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }

                // Stats row
                HStack(spacing: 16) {
                    // Rating
                    HStack(spacing: 4) {
                        RatingStars(rating: bathroom.averageRating, starSize: 12)
                        Text(String(format: "%.1f", bathroom.averageRating))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("(\(bathroom.totalReviews))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Usage count
                    HStack(spacing: 4) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                        Text("\(bathroom.totalUses)")
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }

    private func formatDistance(meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0fm", meters)
        } else {
            let kilometers = meters / 1000
            return String(format: "%.1fkm", kilometers)
        }
    }
}

// Main Content View
struct BathroomLeaderboardContentView: View {
    var body: some View {
        Leaderboard()
    }
}

// Preview for testing
struct BathroomLeaderboardContentView_Previews: PreviewProvider {
    static var previews: some View {
        BathroomLeaderboardContentView()
    }
}


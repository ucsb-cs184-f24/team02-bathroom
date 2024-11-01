//
//  Leaderboard.swift
//  ucsb-bathrooms
//
//  Created by Megumi Ondo on 10/28/24.
//

import SwiftUI

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
    // Sort bathrooms by average rating first, then by review count for popularity
    let bathrooms = sampleBathrooms
        .sorted {
            if $0.averageRating == $1.averageRating {
                return $0.reviewCount > $1.reviewCount
            } else {
                return $0.averageRating > $1.averageRating
            }
        }
    
    let recentReviews = sampleReviews.sorted { $0.timestamp > $1.timestamp }
    
    var body: some View {
        VStack {
            // Top Rated Bathrooms Section
            Text("Top Rated Bathrooms")
                .font(.title2)
                .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(bathrooms.prefix(3)) { bathroom in
                        VStack {
                            Text(bathroom.name)
                                .font(.headline)
                            
                            StarRatingView(rating: bathroom.averageRating)
                                .padding(.top, 2)
                            
                            Text("\(String(format: "%.1f", bathroom.averageRating))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            
            // Top Rated Bathrooms Section
            Text("Recent Reviews")
                .font(.title2)
                .padding(.top, 20)
            
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(recentReviews) { review in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(review.reviewerName) on \(review.bathroomName)")
                                .font(.headline)
                            
                            Text(review.text)
                                .font(.subheadline)
                            
                            Text(review.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
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


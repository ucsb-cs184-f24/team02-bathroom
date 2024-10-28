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
    
    var body: some View {
        NavigationView {
            List(bathrooms) { bathroom in
                HStack {
                    VStack(alignment: .leading) {
                        Text(bathroom.name)
                            .font(.headline)
                        
                        // Star rating view
                        StarRatingView(rating: bathroom.averageRating)
                            .padding(.top, 2)
                        
                        Text("\(String(format: "%.1f", bathroom.averageRating))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(bathroom.reviewCount) reviews")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Top Bathroom Ratings")
        }
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

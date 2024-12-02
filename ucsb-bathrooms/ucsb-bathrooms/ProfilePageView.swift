//
//  ProfilePageView.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/22/24.
//

import SwiftUI
import FirebaseFirestore

struct ProfilePageView: View {
    @Binding var userFullName: String
    @Binding var userEmail: String
    @Binding var isAuthenticated: Bool
    @State private var selectedTab: ProfileTab = .reviews
    @State private var userReviews: [FirestoreManager.Review] = []
    @State private var favoriteBathrooms: [FirestoreManager.Bathroom] = []
    @State private var totalUses: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header with Avatar
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(userFullName.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.blue)
                        )

                    VStack(spacing: 4) {
                        Text(userFullName)
                            .font(.title2)
                            .bold()
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)

                // Stats Cards - now just showing Total Uses and Reviews
                HStack(spacing: 15) {
                    StatCard(title: "Total Uses", value: "\(totalUses)", icon: "person.fill")
                    StatCard(title: "Reviews", value: "\(userReviews.count)", icon: "star.fill")
                }
                .padding(.horizontal)

                // Segmented Control with custom styling
                Picker("Select Tab", selection: $selectedTab) {
                    ForEach(ProfileTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Content Section
                LazyVStack(spacing: 16) {
                    if selectedTab == .reviews {
                        if userReviews.isEmpty {
                            EmptyStateView(
                                icon: "star.slash",
                                message: "No reviews yet",
                                subtitle: "Your reviews will appear here"
                            )
                        } else {
                            ForEach(userReviews) { review in
                                ReviewCard(review: review)
                                    .transition(.opacity)
                            }
                        }
                    } else {
                        if favoriteBathrooms.isEmpty {
                            EmptyStateView(
                                icon: "heart.slash",
                                message: "No favorites yet",
                                subtitle: "Your favorite bathrooms will appear here"
                            )
                        } else {
                            ForEach(favoriteBathrooms) { bathroom in
                                NavigationLink(destination: BathroomDetailView(
                                    bathroomID: bathroom.id,
                                    location: bathroom.name,
                                    gender: bathroom.gender
                                )) {
                                    FavoriteBathroomCard(bathroom: bathroom)
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut, value: selectedTab)
            }
        }
        .task {
            await loadUserReviews()
            await loadTotalUses()
            await loadFavoriteBathrooms()
        }
    }

    private func loadFavoriteBathrooms() async {
        do {
            favoriteBathrooms = try await FirestoreManager.shared.getFavoriteBathrooms()
        } catch {
            print("Error loading favorite bathrooms: \(error)")
        }
    }

    private func loadUserReviews() async {
        do {
            userReviews = try await FirestoreManager.shared.getUserReviews(forUserID: userEmail)
        } catch {
            print("Error loading user reviews: \(error)")
        }
    }

    private func loadTotalUses() async {
        do {
            let total = try await FirestoreManager.shared.getTotalUserUses(userId: userEmail)
            await MainActor.run {
                totalUses = total
            }
        } catch {
            print("Error loading total uses: \(error)")
        }
    }
}

enum ProfileTab: String, CaseIterable {
    case reviews, favorites
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(message)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct FavoriteBathroomCard: View {
    let bathroom: FirestoreManager.Bathroom

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bathroom.name)
                        .font(.headline)
                    Text(bathroom.buildingName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        RatingStars(rating: bathroom.averageRating)
                        Text(String(format: "%.1f", bathroom.averageRating))
                            .bold()
                    }
                    Text("\(bathroom.totalUses) visits")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing: 12) {
                Label("Floor \(bathroom.floor)", systemImage: "stairs")
                Text("•")
                Label(bathroom.gender, systemImage: "person.fill")
            }
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 2)
    }
}

struct ReviewCard: View {
    let review: FirestoreManager.Review
    @State private var bathroomName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(bathroomName)
                        .font(.headline)
                    Text(review.userEmail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                RatingStars(rating: review.rating)
            }

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let imageURL = review.imageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            Task {
                do {
                    let bathroom = try await FirestoreManager.shared.getBathroom(id: review.bathroomId)
                    await MainActor.run {
                        bathroomName = bathroom.name
                    }
                } catch {
                    print("Error loading bathroom name: \(error)")
                }
            }
        }
    }
}

#Preview {
    ProfilePageView(userFullName: .constant("User Name"), userEmail: .constant("user@example.com"), isAuthenticated: .constant(true))
}

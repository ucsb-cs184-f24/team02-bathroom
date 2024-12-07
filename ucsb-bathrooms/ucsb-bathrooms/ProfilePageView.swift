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
    @State private var userReviews: [FirestoreManager.Review] = []
    @State private var totalUses: Int = 0
    @State private var showSignOutAlert = false
    @State private var favoriteBathrooms: [FirestoreManager.Bathroom] = []
    @State private var selectedTab = 0
    @State private var visitHistory: [FirestoreManager.Visit] = []
    @State private var isRefreshing = false
    @State private var bathroomNames: [String: String] = [:]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header Card
                    VStack(spacing: 20) {
                        // Profile Image
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.blue)
                                    .padding(8)
                            )
                            .padding(.top)

                        // User Info
                        VStack(spacing: 8) {
                            Text(userFullName)
                                .font(.title2)
                                .bold()

                            Text(userEmail)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        // Stats Card
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Total Visits",
                                value: "\(totalUses)",
                                icon: "person.3.fill",
                                color: .blue
                            )

                            StatCard(
                                title: "Reviews",
                                value: "\(userReviews.count)",
                                icon: "star.fill",
                                color: .yellow
                            )

                            StatCard(
                                title: "Favorites",
                                value: "\(favoriteBathrooms.count)",
                                icon: "heart.fill",
                                color: .red
                            )
                        }
                        .padding(.vertical)
                    }
                    .padding()
  

                    // Updated Tab Buttons
                    HStack(spacing: 0) {
                        ProfileTabButton(
                            title: "Reviews",
                            icon: "star.fill",
                            isSelected: selectedTab == 0
                        ) {
                            withAnimation { selectedTab = 0 }
                        }

                        ProfileTabButton(
                            title: "Favorites",
                            icon: "heart.fill",
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation { selectedTab = 1 }
                        }

                        ProfileTabButton(
                            title: "History",
                            icon: "clock.fill",
                            isSelected: selectedTab == 2
                        ) {
                            withAnimation { selectedTab = 2 }
                        }
                    }
                    .padding(.horizontal)


                    Divider()

                    // Content based on selected tab
                    switch selectedTab {
                    case 0:
                        ReviewsTabView(reviews: userReviews) { review in
                            Task {
                                do {
                                    try await FirestoreManager.shared.deleteReview(
                                        reviewId: review.id,
                                        bathroomId: review.bathroomId
                                    )
                                    await MainActor.run {
                                        userReviews.removeAll { $0.id == review.id }
                                    }
                                } catch {
                                    print("Error deleting review: \(error)")
                                }
                            }
                        }
                    case 1:
                        FavoritesTabView(bathrooms: favoriteBathrooms)
                    case 2:
                        HistoryTabView(visits: visitHistory)
                    default:
                        EmptyView()
                    }
                }
            }
            .refreshable {
                // Reload all data
                await refreshData()
            }
            .background(Color("bg"))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .bold()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .task {
                await loadUserReviews()
                await loadFavorites()
                await loadVisitHistory()
                if !userEmail.isEmpty {
                    await loadTotalUses()
                }
            }
        }
    }

    private func loadUserReviews() async {
        do {
            userReviews = try await FirestoreManager.shared.getUserReviews(
                userEmail: userEmail,
                isCurrentUser: true
            )
        } catch {
            print("Error loading user reviews: \(error)")
        }
    }

    private func loadTotalUses() async {
        do {
            let totalCount = try await FirestoreManager.shared.getTotalUses(forUserId: userEmail)
            await MainActor.run {
                totalUses = totalCount
            }
        } catch {
            print("Error loading total uses: \(error)")
        }
    }

    private func loadFavorites() async {
        do {
            guard !userEmail.isEmpty else { return }
            favoriteBathrooms = try await FirestoreManager.shared.getFavoriteBathrooms(userId: userEmail)
            print("Loaded \(favoriteBathrooms.count) favorites for user: \(userEmail)")
        } catch {
            print("Error loading favorites: \(error)")
            favoriteBathrooms = []
        }
    }

    private func loadVisitHistory() async {
        do {
            visitHistory = try await FirestoreManager.shared.getVisitHistory(userId: userEmail)
        } catch {
            print("Error loading visit history: \(error)")
            visitHistory = []
        }
    }

    func signOut() {
        userFullName = ""
        userEmail = ""
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "userFullName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
    }

    private func refreshData() async {
        await loadUserReviews()
        await loadFavorites()
        await loadVisitHistory()
        if !userEmail.isEmpty {
            await loadTotalUses()
        }
    }

    private func deleteReview(_ review: FirestoreManager.Review) {
        Task {
            do {
                try await FirestoreManager.shared.deleteReview(reviewId: review.id, bathroomId: review.bathroomId)
                await MainActor.run {
                    userReviews.removeAll { $0.id == review.id }
                }
            } catch {
                print("Error deleting review: \(error)")
            }
        }
    }
}

// Helper Components
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct FavoriteBathroomCard: View {
    let bathroom: FirestoreManager.Bathroom

    var body: some View {
        NavigationLink(
            destination: BathroomDetailView(
                bathroomID: bathroom.id,
                location: bathroom.name,
                gender: bathroom.gender
            )
        ) {
            HStack(spacing: 16) {
                Image(systemName: "toilet")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(bathroom.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Label(
                            String(format: "%.1f", bathroom.averageRating),
                            systemImage: "star.fill"
                        )
                        .foregroundColor(.yellow)

                        Text("•")
                            .foregroundColor(.gray)

                        Text(bathroom.gender)
                            .foregroundColor(Color("accent"))
                    }
                    .font(.subheadline)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color("bg1"))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct ProfileTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color("accent").opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? Color("accent") : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileReviewCard: View {
    let review: FirestoreManager.Review
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    @State private var bathroomName: String = ""

    var body: some View {
        NavigationLink(
            destination: BathroomDetailView(
                bathroomID: review.bathroomId,
                location: bathroomName,
                gender: ""  // This will be updated when the bathroom loads
            )
        ) {
            HStack(alignment: .top, spacing: 12) {
                // Review Icon
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 20))
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 6) {
                    // Bathroom Name and Rating
                    HStack(alignment: .center, spacing: 8) {
                        if !bathroomName.isEmpty {
                            Text(bathroomName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        // Rating Badge
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 11))
                            Text(String(format: "%.1f", review.rating))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        Spacer()

                        // Delete Button
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.system(size: 14))
                        }
                        .alert("Delete Review", isPresented: $showDeleteAlert) {
                            Button("Delete", role: .destructive) {
                                onDelete()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }

                    // Comment
                    if !review.comment.isEmpty {
                        Text(review.comment)
                            .font(.system(size: 14))
                            .foregroundColor(.primary.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Timestamp
                    Text(review.createdAt.dateValue().formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("bg1"))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 4)
        .task {
            do {
                let bathroom = try await FirestoreManager.shared.getBathroom(id: review.bathroomId)
                await MainActor.run {
                    bathroomName = bathroom.name
                }
            } catch {
                print("Error fetching bathroom name: \(error)")
                bathroomName = "Unknown Location"
            }
        }
    }
}

struct HistoryTabView: View {
    let visits: [FirestoreManager.Visit]

    var body: some View {
        LazyVStack(spacing: 12) {
            if visits.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.xmark",
                    message: "No visits yet"
                )
            } else {
                ForEach(visits) { visit in
                    VisitHistoryCard(visit: visit)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.top)
    }
}

struct VisitHistoryCard: View {
    let visit: FirestoreManager.Visit
    @State private var bathroomName: String = ""

    var body: some View {
        HStack(spacing: 16) {
            // Visit Icon
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "figure.walk")
                        .foregroundColor(.green)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(bathroomName)
                    .font(.headline)

                Text(formatDate(visit.timestamp))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color("bg1"))
        .cornerRadius(12)
        .shadow(radius: 2)
        .task {
            do {
                let bathroom = try await FirestoreManager.shared.getBathroom(id: visit.bathroomId)
                await MainActor.run {
                    bathroomName = bathroom.name
                }
            } catch {
                print("Error loading bathroom name: \(error)")
                bathroomName = "Unknown Location"
            }
        }
    }

    private func formatDate(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
}

struct ReviewsTabView: View {
    let reviews: [FirestoreManager.Review]
    let onDeleteReview: (FirestoreManager.Review) -> Void

    var body: some View {
        LazyVStack(spacing: 12) {
            if reviews.isEmpty {
                EmptyStateView(
                    icon: "star.slash",
                    message: "No reviews yet"
                )
            } else {
                ForEach(reviews) { review in
                    ProfileReviewCard(review: review, onDelete: {
                        onDeleteReview(review)
                    })
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
    }
}

struct FavoritesTabView: View {
    let bathrooms: [FirestoreManager.Bathroom]

    var body: some View {
        LazyVStack(spacing: 12) {
            if bathrooms.isEmpty {
                EmptyStateView(
                    icon: "heart.slash",
                    message: "No favorites yet"
                )
            } else {
                ForEach(bathrooms) { bathroom in
                    FavoriteBathroomCard(bathroom: bathroom)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.top)
    }
}

struct PrivacySettingsView: View {
    @Binding var isProfilePrivate: Bool
    @Binding var displayName: String

    var body: some View {
        Form {
            Section(header: Text("Profile Privacy")) {
                Toggle("Private Profile", isOn: $isProfilePrivate)

                if isProfilePrivate {
                    Text("Only you can see your profile")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text("Display Name")) {
                TextField("Display Name", text: $displayName)
            }
        }
    }
}

#Preview {
    ProfilePageView(userFullName: .constant("Test User"), userEmail: .constant("test@example.com"), isAuthenticated: .constant(true))
}

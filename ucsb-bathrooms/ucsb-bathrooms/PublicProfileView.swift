import SwiftUI
import FirebaseFirestore

struct PublicProfileView: View {
    let userId: String
    @State private var user: FirestoreManager.User?
    @State private var userReviews: [FirestoreManager.Review] = []
    @State private var totalUses: Int = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @AppStorage("userEmail") private var currentUserEmail: String = ""
    @Environment(\.presentationMode) var presentationMode

    private func loadUserData() async {
        isLoading = true
        do {
            if let fetchedUser = try await FirestoreManager.shared.getUserByEmail(email: userId) {
                user = fetchedUser

                if !fetchedUser.isProfilePrivate || fetchedUser.email == currentUserEmail {
                    async let reviews = FirestoreManager.shared.getUserReviews(
                        userEmail: userId,
                        isCurrentUser: userId == currentUserEmail
                    )
                    async let uses = FirestoreManager.shared.getTotalUses(forUserId: userId)

                    let (fetchedReviews, fetchedUses) = try await (reviews, uses)

                    await MainActor.run {
                        userReviews = fetchedReviews
                        totalUses = fetchedUses
                        isLoading = false
                    }
                } else {
                    isLoading = false
                }
            } else {
                errorMessage = "User not found"
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error loading profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .edgesIgnoringSafeArea(.all)

            if isLoading {
                ProgressView("Loading profile...")
                    .padding()
            } else if let error = errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if let user = user {
                if user.isProfilePrivate && user.email != currentUserEmail {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("Private Profile")
                            .font(.title2)
                            .bold()

                        Text("This profile is set to private")
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.blue)
                                            .padding(8)
                                    )

                                Text(user.displayName)
                                    .font(.title2)
                                    .bold()

                                HStack(spacing: 20) {
                                    PublicProfileStatCard(
                                        title: "Reviews",
                                        value: "\(userReviews.count)",
                                        icon: "star.fill",
                                        color: .yellow
                                    )

                                    PublicProfileStatCard(
                                        title: "Total Visits",
                                        value: "\(totalUses)",
                                        icon: "figure.walk",
                                        color: .green
                                    )
                                }
                            }
                            .padding()

                            if !userReviews.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Recent Reviews")
                                        .font(.title3)
                                        .bold()
                                        .padding(.horizontal)

                                    ForEach(userReviews) { review in
                                        PublicProfileReviewCard(review: review)
                                            .padding(.horizontal)
                                    }
                                }
                            } else {
                                Text("No reviews yet")
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .task {
            await loadUserData()
        }
    }
}

// Helper view for displaying reviews
struct PublicProfileReviewCard: View {
    let review: FirestoreManager.Review

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= Int(review.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                }

                Spacer()

                // Date
                Text(formatDate(review.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.body)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }

    private func formatDate(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp.dateValue())
    }
}

// Helper view for stat cards
struct PublicProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 24))

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}


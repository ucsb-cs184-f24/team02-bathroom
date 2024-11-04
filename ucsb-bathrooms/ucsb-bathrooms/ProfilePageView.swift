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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text(userFullName)
                            .font(.title2)
                            .bold()

                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()

                    // Usage Statistics
                    HStack {
                        VStack {
                            Text("\(totalUses)")
                                .font(.title)
                                .bold()
                            Text("Total Visits")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    .padding(.horizontal)

                    // Reviews Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("My Reviews")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        if userReviews.isEmpty {
                            Text("No reviews yet")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(userReviews) { review in
                                ReviewCard(review: review)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Text("Sign Out")
                            .foregroundColor(.red)
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
                if !userEmail.isEmpty {
                    await loadTotalUses()
                }
            }
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

    func signOut() {
        userFullName = ""
        userEmail = ""
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "userFullName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
    }
}

struct ReviewCard: View {
    let review: FirestoreManager.Review
    @State private var bathroomName: String = ""

    var formattedDate: String {
        let date = review.createdAt.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bathroom Name and Date
            HStack {
                if !bathroomName.isEmpty {
                    Text(bathroomName)
                        .font(.headline)
                }
                Spacer()
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Rating Stars
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= Int(review.rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                }
                Text(String(format: "%.1f", review.rating))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Review Text (if not empty)
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
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
    ProfilePageView(userFullName: .constant("Test User"), userEmail: .constant("test@example.com"), isAuthenticated: .constant(true))
}

import SwiftUI
import FirebaseFirestore

struct BathroomDetailView: View {
    let bathroomID: String
    @State var location: String
    @State var gender: String

    @State private var reviewText: String = ""
    @State private var rating: Int = 3
    @State private var reviews: [FirestoreManager.Review] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var bathroom: FirestoreManager.Bathroom?
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false

    private func loadBathroomData() async {
        do {
            let updatedBathroom = try await FirestoreManager.shared.getBathroom(id: bathroomID)
            await MainActor.run {
                bathroom = updatedBathroom
                location = updatedBathroom.name
                gender = updatedBathroom.gender
            }
        } catch {
            print("Error loading bathroom: \(error)")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(location)
                        .font(.title2)
                        .bold()

                    HStack(spacing: 16) {
                        Label(gender, systemImage: "person.fill")
                            .foregroundColor(.blue)

                        if let bathroom = bathroom {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(bathroom.averageRating) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14))
                                }
                                Text(String(format: "%.1f", bathroom.averageRating))
                                    .foregroundColor(.gray)
                                Text("(\(bathroom.totalReviews))")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 2)

                // Review Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Write a Review")
                        .font(.headline)

                    // Star Rating
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(star <= rating ? .yellow : .gray)
                                .font(.system(size: 24))
                                .onTapGesture {
                                    withAnimation {
                                        rating = star
                                    }
                                }
                        }
                    }

                    TextField("Share your experience...", text: $reviewText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4, reservesSpace: true)

                    Button {
                        Task {
                            await handleSubmitReview()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Submit Review")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(reviewText.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(reviewText.isEmpty || isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 2)

                // Reviews Section
                if !reviews.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reviews")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(reviews) { review in
                            ReviewCardView(review: review)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .alert("Review Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadBathroomData()
            await loadReviews()
        }
    }

    private func handleSubmitReview() async {
        print("Debug - Auth State: \(isAuthenticated)")
        print("Debug - User Email: \(userEmail)")

        // Check authentication first
        guard isAuthenticated else {
            alertMessage = "Please sign in to submit a review"
            showAlert = true
            return
        }

        // Validate email
        guard !userEmail.isEmpty else {
            print("Debug - Email is empty but user is authenticated")
            // Try to get email from UserDefaults directly
            if let email = UserDefaults.standard.string(forKey: "userEmail") {
                userEmail = email
            } else {
                alertMessage = "Error: Unable to get user email. Please sign out and sign in again."
                showAlert = true
                return
            }
            return
        }

        isLoading = true

        do {
            print("Submitting review for bathroom: \(bathroomID)")
            print("User email: \(userEmail)")
            print("Rating: \(rating)")
            print("Comment: \(reviewText)")

            try await FirestoreManager.shared.addReview(
                bathroomId: bathroomID,
                userId: userEmail,
                rating: Double(rating),
                comment: reviewText
            )

            // Refresh both reviews and bathroom data
            await loadReviews()
            await loadBathroomData()

            await MainActor.run {
                reviewText = ""
                rating = 3
                isLoading = false
                alertMessage = "Review submitted successfully!"
                showAlert = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                alertMessage = "Error submitting review: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func loadReviews() async {
        do {
            let fetchedReviews = try await FirestoreManager.shared.getReviews(forBathroomID: bathroomID)
            await MainActor.run {
                reviews = fetchedReviews
            }
        } catch {
            print("Error loading reviews: \(error.localizedDescription)")
        }
    }
}

struct ReviewCardView: View {
    let review: FirestoreManager.Review

    private func formatDate(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
                Text(review.userId.components(separatedBy: "@").first ?? "User")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text(formatDate(review.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= Int(review.rating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                }
                Text(String(format: "%.1f", review.rating))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Text(review.comment)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

import SwiftUI
import FirebaseFirestore

struct BathroomDetailView: View {
    let bathroomID: String
    @State var location: String
    @State var gender: String

    @State private var reviewText: String = ""
    @State private var rating: Int? = nil
    @State private var reviews: [FirestoreManager.Review] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var bathroom: FirestoreManager.Bathroom?
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
    @State private var usageCount: Int = 0
    @State private var showingUsageAlert = false
    @State private var isFavorite: Bool = false
    @State private var isAnonymous: Bool = false
    @State private var isPrivateProfile: Bool = false
    @FocusState private var isTextEditorFocused: Bool

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

    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Bathroom Info Section
                if let bathroom = bathroom {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(location)
                            .font(.title2)
                            .bold()

                        VStack(spacing: 12) {
                            // Rating Stats
                            HStack(spacing: 16) {
                                Label(gender, systemImage: "person.fill")
                                    .foregroundColor(.blue)

                                HStack(spacing: 4) {
                                    RatingStars(rating: bathroom.averageRating)
                                    Text(String(format: "%.1f", bathroom.averageRating))
                                        .foregroundColor(.gray)
                                    Text("(\(bathroom.totalReviews))")
                                        .foregroundColor(.gray)
                                }
                            }

                            Divider()

                            // Usage Stats
                            HStack(spacing: 20) {
                                // Total Uses
                                VStack {
                                    HStack {
                                        Image(systemName: "person.3.fill")
                                            .foregroundColor(.blue)
                                        Text("\(bathroom.totalUses)")
                                            .font(.headline)
                                    }
                                    Text("Total Visits")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                // Your Uses
                                if usageCount > 0 {
                                    VStack {
                                        HStack {
                                            Image(systemName: "person.fill.checkmark")
                                                .foregroundColor(.green)
                                            Text("\(usageCount)")
                                                .font(.headline)
                                        }
                                        Text("Your Visits")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            HStack(spacing: 16) {
                                // Visit Log Button
                                Button(action: {
                                    Task {
                                        await logVisit()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Log Visit")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }

                                // Favorite Button
                                Button(action: toggleFavorite) {
                                    HStack {
                                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        Text(isFavorite ? "Favorited" : "Favorite")
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isFavorite ? Color.red : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }

                // Review Form
                if isAuthenticated {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Write a Review")
                            .font(.headline)

                        // Rating Stars
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
                                    .foregroundColor(star <= (rating ?? 0) ? .yellow : .gray)
                                    .font(.system(size: 24))
                                    .onTapGesture {
                                        withAnimation {
                                            rating = star
                                        }
                                    }
                            }
                        }

                        // Review Text
                        ZStack(alignment: .topLeading) {
                            if reviewText.isEmpty {
                                Text("Write your review here...")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $reviewText)
                                .frame(minHeight: 100)
                                .focused($isTextEditorFocused)
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        // Anonymous Toggle
                        Toggle("Post Anonymously", isOn: $isAnonymous)

                        // Submit Button
                        Button {
                            isTextEditorFocused = false
                            Task {
                                await submitReview()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("Submit Review")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || rating == nil || reviewText.isEmpty)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }

                // Reviews List
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(reviews) { review in
                        ReviewCardView(review: review) {
                            Task {
                                await loadReviews()
                                await loadBathroomData()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Review Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                await loadBathroomData()
                await loadReviews()
                await loadUserUsageCount()
                await loadFavoriteStatus()
            }
        }
        .onChange(of: isTextEditorFocused) { focused in
            if !focused {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                             to: nil, from: nil, for: nil)
            }
        }
        .alert("Visit Logged!", isPresented: $showingUsageAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your visit has been recorded. You've visited this bathroom \(usageCount) times.")
        }
    }

    private func submitReview() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            try await FirestoreManager.shared.addReview(
                bathroomId: bathroom?.id ?? "",
                rating: Double(rating ?? 0),
                comment: reviewText,
                isAnonymous: isAnonymous
            )

            await MainActor.run {
                reviewText = ""
                rating = nil
                isLoading = false
                alertMessage = "Review submitted successfully!"
                showAlert = true
            }

            await loadBathroomData()
            await loadReviews()
        } catch {
            await MainActor.run {
                isLoading = false
                alertMessage = error.localizedDescription
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

    private func loadUserUsageCount() async {
        do {
            let counts = try await FirestoreManager.shared.getUserUsageCounts(userId: userEmail)
            let thisCount = counts.first { $0.bathroomId == bathroomID }
            await MainActor.run {
                usageCount = thisCount?.count ?? 0
            }
        } catch {
            print("Error loading usage count: \(error)")
        }
    }

    private func logVisit() async {
        Task {
            do {
                try await FirestoreManager.shared.logBathroomVisit(bathroomId: bathroom?.id ?? "")

                // Optimistically update both counts immediately
                await MainActor.run {
                    // Update personal usage count
                    usageCount += 1

                    // Create new bathroom instance with incremented total uses
                    if let currentBathroom = bathroom {
                        bathroom = FirestoreManager.Bathroom(
                            id: currentBathroom.id,
                            name: currentBathroom.name,
                            buildingName: currentBathroom.buildingName,
                            floor: currentBathroom.floor,
                            location: currentBathroom.location,
                            averageRating: currentBathroom.averageRating,
                            totalReviews: currentBathroom.totalReviews,
                            gender: currentBathroom.gender,
                            createdAt: currentBathroom.createdAt,
                            totalUses: currentBathroom.totalUses + 1  // Increment total uses
                        )
                    }
                    showingUsageAlert = true
                }
            } catch {
                print("Error logging visit: \(error)")
                // Revert optimistic updates if the operation fails
                await MainActor.run {
                    usageCount -= 1
                    if let currentBathroom = bathroom {
                        bathroom = FirestoreManager.Bathroom(
                            id: currentBathroom.id,
                            name: currentBathroom.name,
                            buildingName: currentBathroom.buildingName,
                            floor: currentBathroom.floor,
                            location: currentBathroom.location,
                            averageRating: currentBathroom.averageRating,
                            totalReviews: currentBathroom.totalReviews,
                            gender: currentBathroom.gender,
                            createdAt: currentBathroom.createdAt,
                            totalUses: currentBathroom.totalUses - 1
                        )
                    }
                }
            }
        }
    }

    private func loadFavoriteStatus() async {
        guard isAuthenticated else { return }
        do {
            isFavorite = try await FirestoreManager.shared.isBathroomFavorited(bathroomId: bathroomID)
        } catch {
            print("Error loading favorite status: \(error)")
        }
    }

    private func toggleFavorite() {
        Task {
            do {
                try await FirestoreManager.shared.toggleFavorite(bathroomId: bathroomID)
                isFavorite.toggle()
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
}

struct ReviewCardView: View {
    let review: FirestoreManager.Review
    @AppStorage("userEmail") private var userEmail: String = ""
    @State private var showDeleteConfirmation = false
    var onDelete: () -> Void = {}

    private var isOwnReview: Bool {
        return review.userEmail == userEmail
    }

    private var displayName: String {
        if review.isAnonymous {
            return String.randomAnonymousID(seed: review.userId)
        }
        return review.userEmail.components(separatedBy: "@").first ?? "User"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with delete button
            HStack {
                // User info
                HStack {
                    Image(systemName: review.isAnonymous ? "person.fill.questionmark" : "person.circle.fill")
                        .foregroundColor(.gray)
                    Text(displayName)
                        .font(.subheadline)
                        .bold()
                }

                Spacer()

                // Date and delete button
                HStack(spacing: 12) {
                    Text(review.createdAt.formatTimestamp())
                        .font(.caption)
                        .foregroundColor(.gray)

                    if isOwnReview {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red.opacity(0.8))
                                .font(.system(size: 22))
                        }
                    }
                }
            }

            // Rating
            HStack(spacing: 4) {
                StarRatingView(rating: review.rating)
                Text(String(format: "%.1f", review.rating))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Comment
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
        .alert("Delete Review", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await FirestoreManager.shared.deleteReview(
                            reviewId: review.id,
                            bathroomId: review.bathroomId
                        )
                        onDelete()
                    } catch {
                        print("Error deleting review: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this review? This action cannot be undone.")
        }
    }
}

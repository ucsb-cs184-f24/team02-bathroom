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
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isFavorite: Bool = false
    @State private var isAnonymous: Bool = false
    @State private var isPrivateProfile: Bool = false

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
            VStack(alignment: .leading, spacing: 24) {
                // Header Section with Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text(location)
                        .font(.title2)
                        .bold()

                    if let bathroom = bathroom {
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
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(radius: 2)

                // Log Visit Button
                HStack {
                    Button {
                        Task {
                            await logVisit()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Visit")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(10)
                    }
                    .disabled(!isAuthenticated)

                    // Favorite Button
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(isFavorite ? .red : .gray)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .disabled(!isAuthenticated)
                }

                // Review Input Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Write a Review")
                        .font(.headline)

                    // Star Rating
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

                    TextEditor(text: $reviewText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    Toggle("Post Anonymously", isOn: $isAnonymous)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    Button(action: { showImagePicker = true }) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedImage == nil ? "Add Photo" : "Change Photo")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }

                    Button {
                        Task {
                            await submitReview()
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
                        .background(reviewText.isEmpty || rating == nil ? Color.gray.opacity(0.5) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(reviewText.isEmpty || rating == nil || isLoading)
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
                            ReviewCardView(review: review) {
                                Task {
                                    await loadReviews()
                                    await loadBathroomData()
                                }
                            }
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
        .alert("Visit Logged!", isPresented: $showingUsageAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            await loadBathroomData()
            await loadReviews()
            if isAuthenticated {
                await loadUserUsageCount()
                await loadFavoriteStatus()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private func submitReview() {
        guard !isLoading else { return }
        isLoading = true

        Task {
            do {
                // Use either user's profile setting or the toggle setting
                let shouldBeAnonymous = isPrivateProfile || isAnonymous

                try await FirestoreManager.shared.addReview(
                    bathroomId: bathroom?.id ?? "",
                    rating: Double(rating ?? 0),
                    comment: reviewText,
                    image: selectedImage,
                    isAnonymous: shouldBeAnonymous
                )

                await MainActor.run {
                    reviewText = ""
                    rating = nil
                    selectedImage = nil
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
                            totalUses: currentBathroom.totalUses + 1,  // Increment total uses
                            imageURL: currentBathroom.imageURL
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
                            totalUses: currentBathroom.totalUses - 1,
                            imageURL: currentBathroom.imageURL
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
    var onDelete: () -> Void = {}

    private var isOwnReview: Bool {
        return review.userEmail == userEmail
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: review.isAnonymous ? "person.fill.questionmark" : "person.circle.fill")
                    .foregroundColor(.gray)
                Text(review.userEmail.components(separatedBy: "@").first ?? "User")
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text(review.createdAt.formatTimestamp())
                    .font(.caption)
                    .foregroundColor(.gray)

                if isOwnReview {
                    Button(role: .destructive) {
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
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }

            HStack(spacing: 4) {
                StarRatingView(rating: review.rating)
                Text(String(format: "%.1f", review.rating))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Text(review.comment)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

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
    }
}

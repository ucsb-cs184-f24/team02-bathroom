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
    @State private var usageCount: Int = 0
    @State private var showingUsageAlert = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

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
        .alert("Visit Logged!", isPresented: $showingUsageAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            await loadBathroomData()
            await loadReviews()
            if isAuthenticated {
                await loadUserUsageCount()
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
                try await FirestoreManager.shared.addReview(
                    bathroomId: bathroom?.id ?? "",
                    rating: Double(rating),
                    comment: reviewText,
                    image: selectedImage
                )

                await MainActor.run {
                    reviewText = ""
                    rating = 3
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
        do {
            try await FirestoreManager.shared.incrementUsageCount(
                bathroomId: bathroomID,
                userId: userEmail
            )

            // Immediately update the UI
            await MainActor.run {
                usageCount += 1
                if let currentBathroom = bathroom {
                    let updatedBathroom = FirestoreManager.Bathroom(
                        id: currentBathroom.id,
                        name: currentBathroom.name,
                        buildingName: currentBathroom.buildingName,
                        floor: currentBathroom.floor,
                        location: currentBathroom.location,
                        averageRating: currentBathroom.averageRating,
                        totalReviews: currentBathroom.totalReviews,
                        gender: currentBathroom.gender,
                        createdAt: currentBathroom.createdAt,
                        totalUses: currentBathroom.totalUses + 1,
                        imageURL: currentBathroom.imageURL
                    )
                    bathroom = updatedBathroom
                }
                showingUsageAlert = true
            }

            // Refresh the actual data
            await loadBathroomData()
            await loadUserUsageCount()
        } catch {
            print("Error logging visit: \(error)")
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

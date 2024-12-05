import SwiftUI
import FirebaseFirestore
import MapKit
import FirebaseAuth

struct BathroomDetailView: View {
    let bathroomID: String
    @State var location: String
    @State var gender: String

    @State private var reviewText: String = ""
    @State private var rating: Int = 0

    @State private var reviews: [FirestoreManager.Review] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var bathroom: FirestoreManager.Bathroom?
    @AppStorage("userEmail") private var userEmail: String = ""
    @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
    @State private var usageCount: Int = 0
    @State private var showingUsageAlert = false
    @State private var isFavorited = false
    @State private var isCheckingFavorite = true
    @State private var isAnonymous = false
    @State private var personalVisits: Int = 0

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

    private func openInMaps() {
        guard let location = bathroom?.location else { return }

        let coordinates = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )

        let placemark = MKPlacemark(coordinate: coordinates)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = bathroom?.name ?? "Bathroom"

        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(spacing: 16) {
                        if let bathroom = bathroom {
                            // Bathroom Name
                            Text(location)
                                .font(.title2)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Stats Row
                            HStack(spacing: 16) {
                                // Gender
                                HStack(spacing: 4) {
                                    Image(systemName: "figure.dress.line.vertical.figure")
                                        .foregroundColor(.blue)
                                    Text(gender)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }

                                // Rating
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", bathroom.averageRating))
                                        .font(.subheadline)
                                }

                                // Total Uses
                                HStack(spacing: 4) {
                                    Image(systemName: "person.3.fill")
                                        .foregroundColor(.blue)
                                    Text("\(bathroom.totalUses)")
                                        .font(.subheadline)
                                }

                                // Personal Visits
                                HStack(spacing: 4) {
                                    Image(systemName: "figure.walk")
                                        .foregroundColor(.green)
                                    Text("\(personalVisits)")
                                        .font(.subheadline)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Divider()

                            // Action Buttons
                            HStack(spacing: 16) {
                                // Log Visit Button
                                ActionButton(
                                    title: "Log Visit",
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    isEnabled: isAuthenticated
                                ) {
                                    Task { await logVisit() }
                                }

                                // Directions Button
                                ActionButton(
                                    title: "Directions",
                                    icon: "map.fill",
                                    color: .blue,
                                    isEnabled: true
                                ) {
                                    openInMaps()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 2)

                    // Review Input Card
                    if isAuthenticated {
                        ReviewInputCard(
                            rating: $rating,
                            reviewText: $reviewText,
                            isAnonymous: $isAnonymous,
                            isLoading: $isLoading,
                            onSubmit: { Task { await handleSubmitReview() } }
                        )
                    }

                    // Reviews Section
                    if !reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Reviews")
                                .font(.title3)
                                .bold()
                                .padding(.horizontal)

                            LazyVStack(spacing: 16) {
                                ForEach(reviews, id: \.id) { review in
                                    ReviewCardView(
                                        review: review,
                                        onDelete: {
                                            deleteReview(review)
                                        }
                                    )
                                    .transition(.opacity)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarItems(trailing: FavoriteButton(
                isFavorited: $isFavorited,
                isCheckingFavorite: $isCheckingFavorite,
                isAuthenticated: isAuthenticated,
                onToggle: { Task { await toggleFavorite() } }
            ))
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
                    await checkFavoriteStatus()
                    await loadPersonalVisits()
                }

            }
        }
    }

    private func submitReview() async {
        guard !isLoading else { return }
        isLoading = true

        guard let currentUser = Auth.auth().currentUser else {
            // Handle not authenticated case
            return
        }

        do {
            try await FirestoreManager.shared.addReview(
                bathroomId: bathroomID,
                userId: currentUser.uid,  // Ensure this is the Firebase UID
                userEmail: userEmail,
                rating: Double(rating),
                comment: reviewText,
                isAnonymous: isAnonymous
            )

            let newReview = FirestoreManager.Review(
                id: UUID().uuidString,
                bathroomId: bathroomID,
                userId: currentUser.uid,  // Ensure this is the Firebase UID
                userEmail: userEmail,
                rating: Double(rating),
                comment: reviewText,
                createdAt: Timestamp(),

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
        do {
            try await FirestoreManager.shared.incrementUsageCount(
                bathroomId: bathroomID,
                userId: userEmail
            )

            await MainActor.run {
                personalVisits += 1  // Increment personal visits counter
                showingUsageAlert = true
            }

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

    private func checkFavoriteStatus() async {
        guard isAuthenticated else { return }

        do {
            let favorited = try await FirestoreManager.shared.isBathroomFavorited(
                userId: userEmail,
                bathroomId: bathroomID
            )
            await MainActor.run {
                isFavorited = favorited
                isCheckingFavorite = false
            }
        } catch {
            print("Error checking favorite status: \(error)")
            await MainActor.run {
                isCheckingFavorite = false
            }
        }
    }

    private func toggleFavorite() async {
        guard isAuthenticated else { return }

        do {
            if isFavorited {
                try await FirestoreManager.shared.removeFavorite(
                    userId: userEmail,
                    bathroomId: bathroomID
                )
            } else {
                try await FirestoreManager.shared.addFavorite(
                    userId: userEmail,
                    bathroomId: bathroomID
                )
            }
            await MainActor.run {
                isFavorited.toggle()
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }

    private func deleteReview(_ review: FirestoreManager.Review) {
        Task {
            do {
                try await FirestoreManager.shared.deleteReview(
                    reviewId: review.id,
                    bathroomId: bathroomID
                )

                await MainActor.run {
                    // Remove the review from the local array
                    reviews.removeAll { $0.id == review.id }
                    // Reload bathroom data to update ratings
                    Task {
                        await loadBathroomData()
                    }
                }
            } catch {
                print("Error deleting review: \(error)")
            }
        }
    }

    private func loadPersonalVisits() async {
        do {
            let usageId = "\(userEmail)_\(bathroomID)"
            if let usage = try await FirestoreManager.shared.getUsage(id: usageId) {
                await MainActor.run {
                    personalVisits = usage.count
                }
            }
        } catch {
            print("Error loading personal visits: \(error)")
        }
    }
}

struct ReviewCardView: View {
    let review: FirestoreManager.Review
    let onDelete: () -> Void
    @AppStorage("userEmail") private var userEmail: String = ""
    @State private var showDeleteAlert = false
    @State private var showProfile = false

    private var displayName: String {
        if review.isAnonymous {
            if review.userEmail == userEmail {
                return "Anonymous (You)"
            }
            return "Anonymous"
        }
        return review.userEmail.components(separatedBy: "@").first ?? "User"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Profile Picture
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: review.isAnonymous ? "person.fill.questionmark" : "person.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 20))
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)

                        // User Info and Rating
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center, spacing: 8) {
                                if review.isAnonymous {
                                    Text(displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                } else {
                                    Button(action: {
                                        showProfile = true
                                    }) {
                                        Text(displayName)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
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
                            }

                            // Timestamp
                            Text(review.createdAt.dateValue().formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.8))
                        }

                        Spacer()

                        // Delete Button
                        if review.userEmail == userEmail {
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
                    }
                }
            }

            // Comment
            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(size: 14))
                    .foregroundColor(.primary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 44) // Aligns with content after profile picture
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 4)
        .fullScreenCover(isPresented: $showProfile) {
            NavigationView {
                PublicProfileView(userId: review.userEmail)
            }
        }

    }
}

// Helper Views
struct StatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(minWidth: 80)
        .background(color.opacity(0.1))
        .cornerRadius(20)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? color.opacity(0.1) : Color.gray.opacity(0.1))
            .foregroundColor(isEnabled ? color : .gray)
            .cornerRadius(12)
        }
        .disabled(!isEnabled)
    }
}

struct FavoriteButton: View {
    @Binding var isFavorited: Bool
    @Binding var isCheckingFavorite: Bool
    let isAuthenticated: Bool
    let onToggle: () -> Void

    var body: some View {
        if isAuthenticated {
            Button(action: onToggle) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .foregroundColor(isFavorited ? .red : .gray)
                    .font(.title2)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(radius: 2)

            }
            .disabled(isCheckingFavorite)
        }
    }
}

struct ReviewInputCard: View {
    @Binding var rating: Int
    @Binding var reviewText: String
    @Binding var isAnonymous: Bool
    @Binding var isLoading: Bool
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Write a Review")
                .font(.headline)

            // Rating Stars
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(index <= rating ? .yellow : .gray)
                        .font(.title2)
                        .onTapGesture {
                            if rating == index {
                                rating = 0
                            } else {
                                rating = index
                            }
                        }
                }
            }

            // Anonymous Toggle
            Toggle(isOn: $isAnonymous) {
                HStack {
                    Image(systemName: "person.fill.questionmark")
                        .foregroundColor(.gray)
                    Text("Post Anonymously")
                        .foregroundColor(.gray)
                }
            }
            .tint(.blue)

            // Review Text Input
            TextEditor(text: $reviewText)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )

            // Submit Button
            Button(action: onSubmit) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Post Review")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(rating == 0 || reviewText.isEmpty || isLoading ? Color.gray.opacity(0.3) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(rating == 0 || reviewText.isEmpty || isLoading)

        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
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


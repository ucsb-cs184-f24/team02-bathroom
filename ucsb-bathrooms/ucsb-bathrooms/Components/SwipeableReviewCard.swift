import SwiftUI
import Firebase
import FirebaseFirestore

struct SwipeableReviewCard: View {
    let review: FirestoreManager.Review
    let bathroomName: String
    let showBathroomName: Bool
    let onDelete: () -> Void

    @AppStorage("userEmail") private var userEmail: String = ""
    @State private var showDeleteAlert = false

    private var displayName: String {
        if review.isAnonymous {
            if review.userId == userEmail {
                return "Anonymous (You)"
            }
            return "Anonymous"
        }
        return review.userId.components(separatedBy: "@").first ?? "User"
    }

    private func formatDate(_ timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showBathroomName {
                Text(bathroomName)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            HStack(spacing: 12) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: review.isAnonymous ? "person.fill.questionmark" : "person.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))

                    HStack(spacing: 8) {
                        Text(formatDate(review.createdAt))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Circle()
                            .fill(Color.gray)
                            .frame(width: 3, height: 3)

                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= Int(review.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                }

                Spacer()

                if review.userId == userEmail {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.system(size: 15))
                    .lineSpacing(4)
                    .padding(.leading, 52)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .alert("Delete Review", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this review?")
        }
    }
}
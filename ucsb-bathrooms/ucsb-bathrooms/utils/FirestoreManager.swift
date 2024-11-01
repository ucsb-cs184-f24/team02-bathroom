//
//  FirestoreManager.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 11/1/24.
//

import FirebaseFirestore
import FirebaseCore

class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()

    private let db = Firestore.firestore()

    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    // MARK: - Models
    struct User: Identifiable {
        var id: String
        let authProvider: String
        let createdAt: Timestamp
        let email: String
        let fullName: String
        let lastLoginAt: Timestamp
        let reviews: [DocumentReference]
    }
    
    struct Bathroom: Identifiable {
        var id: String
        let buildingName: String
        let floor: Int
        let location: GeoPoint
        let image: String
        var averageRating: Double
        var totalReviews: Int
        let createdAt: Timestamp
    }

    struct Review: Identifiable {
        var id: String
        let bathroomId: String
        let userId: String
        let rating: Double
        let comment: String
        let createdAt: Timestamp
    }

    // MARK: - Fetch Methods
    func getAllBathrooms() async throws -> [Bathroom] {
        let snapshot = try await db.collection("bathrooms").getDocuments()
        return snapshot.documents.compactMap { document in
            try? self.mapDocumentToBathroom(document)
        }
    }

    func getBathroom(withID id: String) async throws -> Bathroom? {
        let document = try await db.collection("bathrooms").document(id).getDocument()
        return try? self.mapDocumentToBathroom(document)
    }

    func getReviews(forBathroomID bathroomID: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("bathroomId", isEqualTo: bathroomID)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            try? self.mapDocumentToReview(document)
        }
    }
    
    func getUser(withID id: String) async throws -> User? {
        let document = try await db.collection("users").document(id).getDocument()
        return try? self.mapDocumentToUser(document)
    }

    // MARK: - Add Methods
    func addBathroom(_ bathroom: Bathroom) async throws {
        let data = try mapBathroomToData(bathroom)
        try await db.collection("bathrooms").addDocument(data: data)
    }

    func addReview(_ review: Review) async throws {
        let data = try mapReviewToData(review)
        try await db.collection("reviews").addDocument(data: data)
    }

    func addUser(_ user: User) async throws {
        let data = try mapUserToData(user)
        try await db.collection("users").addDocument(data: data)
    }
    
    // MARK: - Update Methods
    func updateBathroom(bathroomID: String, data: [String: Any]) async throws {
        try await db.collection("bathrooms").document(bathroomID).updateData(data)
    }

    func updateReview(reviewID: String, data: [String: Any]) async throws {
        try await db.collection("reviews").document(reviewID).updateData(data)
    }

    // MARK: - Delete Methods
    func deleteBathroom(bathroomID: String) async throws {
        try await db.collection("bathrooms").document(bathroomID).delete()
    }

    func deleteReview(reviewID: String) async throws {
        try await db.collection("reviews").document(reviewID).delete()
    }

    // MARK: - Mapping Methods
    private func mapDocumentToBathroom(_ document: DocumentSnapshot) throws -> Bathroom {
        let data = document.data() ?? [:]
        return Bathroom(
            id: document.documentID,
            buildingName: data["buildingName"] as? String ?? "",
            floor: data["floor"] as? Int ?? 0,
            location: data["location"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
            image: data["image"] as? String ?? "",
            averageRating: data["averageRating"] as? Double ?? 0.0,
            totalReviews: data["totalReviews"] as? Int ?? 0,
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp()
        )
    }

    private func mapDocumentToReview(_ document: DocumentSnapshot) throws -> Review {
        let data = document.data() ?? [:]
        return Review(
            id: document.documentID,
            bathroomId: data["bathroomId"] as? String ?? "",
            userId: data["userId"] as? String ?? "",
            rating: data["rating"] as? Double ?? 0.0,
            comment: data["comment"] as? String ?? "",
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp()
        )
    }

    private func mapDocumentToUser(_ document: DocumentSnapshot) throws -> User {
        let data = document.data() ?? [:]
        return User(
            id: document.documentID,
            authProvider: data["authProvider"] as? String ?? "",
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
            email: data["email"] as? String ?? "",
            fullName: data["fullName"] as? String ?? "",
            lastLoginAt: data["lastLoginAt"] as? Timestamp ?? Timestamp(),
            reviews: data["reviews"] as? [DocumentReference] ?? []
        )
    }

    private func mapBathroomToData(_ bathroom: Bathroom) throws -> [String: Any] {
        return [
            "buildingName": bathroom.buildingName,
            "floor": bathroom.floor,
            "location": bathroom.location,
            "image": bathroom.image,
            "averageRating": bathroom.averageRating,
            "totalReviews": bathroom.totalReviews,
            "createdAt": bathroom.createdAt
        ]
    }

    private func mapReviewToData(_ review: Review) throws -> [String: Any] {
        return [
            "bathroomId": review.bathroomId,
            "userId": review.userId,
            "rating": review.rating,
            "comment": review.comment,
            "createdAt": review.createdAt
        ]
    }

    private func mapUserToData(_ user: User) throws -> [String: Any] {
        return [
            "authProvider": user.authProvider,
            "createdAt": user.createdAt,
            "email": user.email,
            "fullName": user.fullName,
            "lastLoginAt": user.lastLoginAt,
            "reviews": user.reviews
        ]
    }
}

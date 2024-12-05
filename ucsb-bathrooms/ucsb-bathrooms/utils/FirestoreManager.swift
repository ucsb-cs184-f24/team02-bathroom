//
//  FirestoreManager.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 11/1/24.
//

import FirebaseFirestore
import FirebaseCore
import FirebaseStorage
import FirebaseAuth

class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()

    private let db = Firestore.firestore()

    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    // MARK: - Models
    struct Bathroom: Identifiable, Equatable {
        let id: String
        let name: String
        let buildingName: String
        let floor: Int
        let location: GeoPoint
        let averageRating: Double
        let totalReviews: Int
        let gender: String
        let createdAt: Timestamp
        let totalUses: Int

        static func == (lhs: Bathroom, rhs: Bathroom) -> Bool {
            return lhs.id == rhs.id
        }
    }

    struct Review: Identifiable {
        let id: String
        let bathroomId: String
        let userId: String
        let userEmail: String
        let rating: Double
        let comment: String
        let createdAt: Timestamp
        let isAnonymous: Bool
    }

    struct User: Identifiable {
        var id: String
        let authProvider: String
        let email: String
        let fullName: String
        let createdAt: Timestamp
        let lastLoginAt: Timestamp
    }

    struct UsageCount: Identifiable {
        let id: String
        let bathroomId: String
        let userId: String
        let count: Int
        let lastUsed: Timestamp
    }

    // MARK: - Bathroom Methods
    func addBathroom(name: String, buildingName: String, floor: Int, latitude: Double, longitude: Double, gender: String) async throws {
        // Create bathroom document
        let bathroomRef = db.collection("bathrooms").document()
        let bathroomData: [String: Any] = [
            "name": name,
            "buildingName": buildingName,
            "floor": floor,
            "location": GeoPoint(latitude: latitude, longitude: longitude),
            "gender": gender,
            "averageRating": 0.0,
            "totalReviews": 0,
            "createdAt": Timestamp(),
            "totalUses": 0
        ]

        try await bathroomRef.setData(bathroomData)
    }

    func getAllBathrooms() async throws -> [Bathroom] {
        let snapshot = try await db.collection("bathrooms").getDocuments()
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return Bathroom(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                buildingName: data["buildingName"] as? String ?? "",
                floor: data["floor"] as? Int ?? 0,
                location: data["location"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
                averageRating: data["averageRating"] as? Double ?? 0.0,
                totalReviews: data["totalReviews"] as? Int ?? 0,
                gender: data["gender"] as? String ?? "",
                createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                totalUses: data["totalUses"] as? Int ?? 0
            )
        }
    }

    // MARK: - Review Methods
    func addReview(bathroomId: String, rating: Double, comment: String, isAnonymous: Bool = false) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let userEmail = Auth.auth().currentUser?.email else {
            throw NSError(domain: "ReviewError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }


        // Create review data
        let reviewData: [String: Any] = [
            "bathroomId": bathroomId,
            "userId": userId,
            "userEmail": userEmail,
            "rating": rating,
            "comment": comment,
            "createdAt": Timestamp(),
            "isAnonymous": isAnonymous
        ]

        // Add review to Firestore
        try await db.collection("reviews").document().setData(reviewData)

        // Update bathroom stats
        try await updateBathroomStats(bathroomId: bathroomId, newRating: rating)
    }

    func getReviews(forBathroomID bathroomId: String) async throws -> [Review] {
        print("Fetching reviews for bathroom: \(bathroomId)")

        let snapshot = try await db.collection("reviews")
            .whereField("bathroomId", isEqualTo: bathroomId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        print("Found \(snapshot.documents.count) reviews")

        return snapshot.documents.compactMap { document in
            let data = document.data()
            return Review(
                id: document.documentID,
                bathroomId: data["bathroomId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                userEmail: data["userEmail"] as? String ?? "",
                rating: data["rating"] as? Double ?? 0.0,
                comment: data["comment"] as? String ?? "",
                createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                isAnonymous: data["isAnonymous"] as? Bool ?? false
            )
        }
    }

    // Add a method to add a bathroom
    func addBathroom(buildingName: String, floor: Int, latitude: Double, longitude: Double, gender: String) async throws {
        let bathroomData: [String: Any] = [
            "buildingName": buildingName,
            "floor": floor,
            "location": GeoPoint(latitude: latitude, longitude: longitude),
            "averageRating": 0.0,
            "totalReviews": 0,
            "createdAt": Timestamp(),
            "gender": gender
        ]

        let docRef = try await db.collection("bathrooms").addDocument(data: bathroomData)
        print("Added bathroom with ID: \(docRef.documentID)")
    }

    // MARK: - User Methods
    func getUser(withID id: String) async throws -> User? {
        let docSnapshot = try await db.collection("users").document(id).getDocument()
        if docSnapshot.exists {
            let data = docSnapshot.data() ?? [:]
            return User(
                id: docSnapshot.documentID,
                authProvider: data["authProvider"] as? String ?? "",
                email: data["email"] as? String ?? "",
                fullName: data["fullName"] as? String ?? "",
                createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                lastLoginAt: data["lastLoginAt"] as? Timestamp ?? Timestamp()
            )
        }
        return nil
    }

    func addUser(_ user: User) async throws {
        let userData: [String: Any] = [
            "authProvider": user.authProvider,
            "email": user.email,
            "fullName": user.fullName,
            "createdAt": user.createdAt,
            "lastLoginAt": user.lastLoginAt
        ]

        try await db.collection("users").document(user.id).setData(userData)
    }

    func updateUserLastLogin(userID: String) async throws {
        let updateData: [String: Any] = [
            "lastLoginAt": Timestamp()
        ]
        try await db.collection("users").document(userID).updateData(updateData)
    }

    // MARK: - User Review Methods
    func getUserReviews(userEmail: String, isCurrentUser: Bool = false) async throws -> [Review] {
        print("Debug - Getting reviews for email: \(userEmail), isCurrentUser: \(isCurrentUser)")


        var query = db.collection("reviews")
            .whereField("userEmail", isEqualTo: userEmail)

        if !isCurrentUser {
            // If not viewing own profile, only show non-anon reviewa
            query = query.whereField("isAnonymous", isEqualTo: false)
        }

        // Add ordering after all filters
        query = query.order(by: "createdAt", descending: true)


        return snapshot.documents.compactMap { document in
            let data = document.data()
            return Review(
                id: document.documentID,
                bathroomId: data["bathroomId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                userEmail: data["userEmail"] as? String ?? "",
                rating: data["rating"] as? Double ?? 0.0,
                comment: data["comment"] as? String ?? "",
                createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                isAnonymous: data["isAnonymous"] as? Bool ?? false
            )
        }
    }

    // MARK: - Bathroom Methods
    func getBathroom(withID id: String) async throws -> Bathroom? {
        let document = try await db.collection("bathrooms").document(id).getDocument()
        guard document.exists else { return nil }

        let data = document.data() ?? [:]
        return Bathroom(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            buildingName: data["buildingName"] as? String ?? "",
            floor: data["floor"] as? Int ?? 0,
            location: data["location"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
            averageRating: data["averageRating"] as? Double ?? 0.0,
            totalReviews: data["totalReviews"] as? Int ?? 0,
            gender: data["gender"] as? String ?? "",
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
            totalUses: data["totalUses"] as? Int ?? 0
        )
    }

    func getBathroom(id: String) async throws -> Bathroom {
        let document = try await db.collection("bathrooms").document(id).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bathroom not found"])
        }

        return Bathroom(
            id: document.documentID,
            name: data["name"] as? String ?? "",
            buildingName: data["buildingName"] as? String ?? "",
            floor: data["floor"] as? Int ?? 0,
            location: data["location"] as? GeoPoint ?? GeoPoint(latitude: 0, longitude: 0),
            averageRating: data["averageRating"] as? Double ?? 0.0,
            totalReviews: data["totalReviews"] as? Int ?? 0,
            gender: data["gender"] as? String ?? "",
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
            totalUses: data["totalUses"] as? Int ?? 0
        )
    }

    // Add this new method to get reviews by user ID
    func getUserReviews(forUserID userId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            let data = document.data()
            return Review(
                id: document.documentID,
                bathroomId: data["bathroomId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                userEmail: data["userEmail"] as? String ?? "",
                rating: data["rating"] as? Double ?? 0.0,
                comment: data["comment"] as? String ?? "",
                createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
                isAnonymous: data["isAnonymous"] as? Bool ?? false
            )
        }
    }

    func incrementUsageCount(bathroomId: String, userId: String) async throws {
        let usageRef = db.collection("usageCounts")
            .document("\(userId)_\(bathroomId)")

        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            let usageDoc = try? transaction.getDocument(usageRef)

            if let doc = usageDoc, doc.exists {
                // Increment existing count
                let currentCount = doc.data()?["count"] as? Int ?? 0
                transaction.updateData([
                    "count": currentCount + 1,
                    "lastUsed": Timestamp()
                ], forDocument: usageRef)
            } else {
                // Create new count
                transaction.setData([
                    "bathroomId": bathroomId,
                    "userId": userId,
                    "count": 1,
                    "lastUsed": Timestamp()
                ], forDocument: usageRef)
            }

            return nil
        })

        // Update total usage count for the bathroom
        let bathroomRef = db.collection("bathrooms").document(bathroomId)
        try await bathroomRef.updateData([
            "totalUses": FieldValue.increment(Int64(1))
        ])
    }

    func getUserUsageCounts(userId: String) async throws -> [UsageCount] {
        let snapshot = try await db.collection("usageCounts")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents.map { doc in
            let data = doc.data()
            return UsageCount(
                id: doc.documentID,
                bathroomId: data["bathroomId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                count: data["count"] as? Int ?? 0,
                lastUsed: data["lastUsed"] as? Timestamp ?? Timestamp()
            )
        }
    }

    func getTotalUserUses(userId: String) async throws -> Int {
        let snapshot = try await db.collection("usageCounts")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents.reduce(0) { sum, doc in
            sum + (doc.data()["count"] as? Int ?? 0)
        }
    }

    private func updateBathroomStats(bathroomId: String, newRating: Double) async throws {
        // Get all reviews for this bathroom
        let snapshot = try await db.collection("reviews")
            .whereField("bathroomId", isEqualTo: bathroomId)
            .getDocuments()

        // Calculate new stats
        let reviews = snapshot.documents
        let totalReviews = reviews.count
        let sumRatings = reviews.reduce(0.0) { sum, document in
            sum + (document.data()["rating"] as? Double ?? 0.0)
        }
        let averageRating = sumRatings / Double(totalReviews)

        // Update bathroom document
        let bathroomRef = db.collection("bathrooms").document(bathroomId)
        try await bathroomRef.updateData([
            "averageRating": averageRating,
            "totalReviews": totalReviews
        ])
    }

    func logBathroomVisit(bathroomId: String) async throws {
        let bathroomRef = db.collection("bathrooms").document(bathroomId)

        try await db.runTransaction { transaction, errorPointer in
            let bathroomDoc: DocumentSnapshot
            do {
                bathroomDoc = try transaction.getDocument(bathroomRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let currentTotalUses = bathroomDoc.data()?["totalUses"] as? Int else {
                let error = NSError(
                    domain: "FirestoreManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve total uses from snapshot \(bathroomDoc)"]
                )
                errorPointer?.pointee = error
                return nil
            }

            transaction.updateData(["totalUses": currentTotalUses + 1], forDocument: bathroomRef)
            return nil
        }
    }

    func toggleFavorite(bathroomId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FavoriteError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let favoriteRef = db.collection("favorites").document("\(userId)_\(bathroomId)")
        let docSnapshot = try await favoriteRef.getDocument()

        if docSnapshot.exists {
            // Remove favorite
            try await favoriteRef.delete()
        } else {
            // Add favorite
            try await favoriteRef.setData([
                "userId": userId,
                "bathroomId": bathroomId,
                "createdAt": Timestamp()
            ])
        }
    }

    func isBathroomFavorited(bathroomId: String) async throws -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }

        let docSnapshot = try await db.collection("favorites")
            .document("\(userId)_\(bathroomId)")
            .getDocument()

        return docSnapshot.exists
    }

    func getFavoriteBathrooms() async throws -> [Bathroom] {
        guard let userId = Auth.auth().currentUser?.uid else { return [] }

        let snapshot = try await db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let bathroomIds = snapshot.documents.map { $0.data()["bathroomId"] as? String ?? "" }

        var favoriteBathrooms: [Bathroom] = []
        for id in bathroomIds {
            if let bathroom = try? await getBathroom(id: id) {
                favoriteBathrooms.append(bathroom)
            }
        }

        return favoriteBathrooms
    }

    func updateUserPrivacySettings(userId: String, isPrivate: Bool) async throws {
        try await db.collection("users").document(userId).setData([
            "isPrivateProfile": isPrivate
        ], merge: true)
    }

    func getUserPrivacySettings(userId: String) async throws -> Bool {
        let doc = try await db.collection("users").document(userId).getDocument()
        return doc.data()?["isPrivateProfile"] as? Bool ?? false
    }

    func deleteReview(reviewId: String, bathroomId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ReviewError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        // Get the review to verify ownership
        let reviewDoc = try await db.collection("reviews").document(reviewId).getDocument()
        guard let reviewData = reviewDoc.data(),
              reviewData["userId"] as? String == userId else {
            throw NSError(domain: "ReviewError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Not authorized to delete this review"])
        }

        // Delete the review
        try await db.collection("reviews").document(reviewId).delete()

        // Update bathroom stats
        try await updateBathroomStats(bathroomId: bathroomId, newRating: 0)
    }
}

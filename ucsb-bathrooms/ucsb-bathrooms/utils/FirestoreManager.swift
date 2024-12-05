//
//  FirestoreManager.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 11/1/24.
//

import Firebase
import FirebaseFirestore
import CoreLocation


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
        var isProfilePrivate: Bool
        var displayName: String
    }

    struct UsageCount: Identifiable {
        let id: String
        let bathroomId: String
        let userId: String
        let count: Int
        let lastUsed: Timestamp
        let logs: [UsageLog]
    }

    struct UsageLog: Identifiable {
        let id: String
        let timestamp: Timestamp
        let bathroomId: String
    }

    struct Favorite: Identifiable {
        let id: String
        let userId: String
        let bathroomId: String
        let createdAt: Timestamp
    }

    struct Visit: Identifiable {
        let id: String
        let userId: String
        let bathroomId: String
        let timestamp: Timestamp
        let count: Int
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
    func addReview(bathroomId: String, userId: String, userEmail: String, rating: Double, comment: String, isAnonymous: Bool) async throws {
        print("Starting to add review to Firestore...")


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
        let snapshot = try await db.collection("reviews")
            .whereField("bathroomId", isEqualTo: bathroomId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

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
                lastLoginAt: data["lastLoginAt"] as? Timestamp ?? Timestamp(),
                isProfilePrivate: data["isProfilePrivate"] as? Bool ?? false,
                displayName: data["displayName"] as? String ?? ""
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
            "lastLoginAt": user.lastLoginAt,
            "isProfilePrivate": user.isProfilePrivate,
            "displayName": user.displayName
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
            // If not viewing own profile, only show non-anonymous reviews
            query = query.whereField("isAnonymous", isEqualTo: false)
        }

        // Add ordering after all filters
        query = query.order(by: "createdAt", descending: true)

        let snapshot = try await query.getDocuments()
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

    func incrementUsageCount(bathroomId: String, userId: String) async throws {
        let usageId = "\(userId)_\(bathroomId)"
        let usageRef = db.collection("usage").document(usageId)
        let bathroomRef = db.collection("bathrooms").document(bathroomId)

        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            // Update usage document
            let usageDoc: DocumentSnapshot
            do {
                usageDoc = try transaction.getDocument(usageRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }


            let currentCount = (usageDoc.data()?["count"] as? Int) ?? 0
            var logs = (usageDoc.data()?["logs"] as? [[String: Any]]) ?? []

            // Create new log entry
            let newLog: [String: Any] = [
                "id": UUID().uuidString,
                "timestamp": Timestamp(),
                "bathroomId": bathroomId
            ]
            logs.append(newLog)

            let usageData: [String: Any] = [
                "userId": userId,
                "bathroomId": bathroomId,
                "count": currentCount + 1,
                "lastUsed": Timestamp(),
                "logs": logs
            ]

            // Update bathroom document
            let bathroomDoc: DocumentSnapshot
            do {
                bathroomDoc = try transaction.getDocument(bathroomRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            let currentTotalUses = (bathroomDoc.data()?["totalUses"] as? Int) ?? 0

            transaction.setData(usageData, forDocument: usageRef)
            transaction.updateData(["totalUses": currentTotalUses + 1], forDocument: bathroomRef)

            return nil
        }
    }

    func getUserUsageCounts(userId: String) async throws -> [UsageCount] {
        let snapshot = try await db.collection("usage")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents.map { document in
            let data = document.data()
            return UsageCount(
                id: document.documentID,
                bathroomId: data["bathroomId"] as? String ?? "",
                userId: data["userId"] as? String ?? "",
                count: data["count"] as? Int ?? 0,
                lastUsed: data["lastUsed"] as? Timestamp ?? Timestamp(),
                logs: (data["logs"] as? [[String: Any]] ?? []).map { logData in
                    UsageLog(
                        id: logData["id"] as? String ?? UUID().uuidString,
                        timestamp: logData["timestamp"] as? Timestamp ?? Timestamp(),
                        bathroomId: logData["bathroomId"] as? String ?? ""
                    )
                }
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

    func addFavorite(userId: String, bathroomId: String) async throws {
        let favoriteId = "\(userId)_\(bathroomId)"
        try await db.collection("favorites").document(favoriteId).setData([
            "userId": userId,
            "bathroomId": bathroomId,
            "createdAt": Timestamp()
        ])
    }

    func removeFavorite(userId: String, bathroomId: String) async throws {
        let favoriteId = "\(userId)_\(bathroomId)"
        try await db.collection("favorites").document(favoriteId).delete()
    }

    func isBathroomFavorited(userId: String, bathroomId: String) async throws -> Bool {
        let favoriteId = "\(userId)_\(bathroomId)"
        let doc = try await db.collection("favorites").document(favoriteId).getDocument()
        return doc.exists
    }

    func getFavoriteBathrooms(userId: String) async throws -> [Bathroom] {
        let snapshot = try await db.collection("favorites")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let bathroomIds = snapshot.documents.map { $0.data()["bathroomId"] as? String ?? "" }

        var bathrooms: [Bathroom] = []
        for id in bathroomIds {
            let bathroomDoc = try await db.collection("bathrooms").document(id).getDocument()
            guard let data = bathroomDoc.data(),
                  let name = data["name"] as? String,
                  let buildingName = data["buildingName"] as? String,
                  let floor = data["floor"] as? Int,
                  let location = data["location"] as? GeoPoint,
                  let gender = data["gender"] as? String,
                  let averageRating = data["averageRating"] as? Double,
                  let totalReviews = data["totalReviews"] as? Int,
                  let totalUses = data["totalUses"] as? Int,
                  let createdAt = data["createdAt"] as? Timestamp else {
                continue
            }

            let bathroom = Bathroom(
                id: id,
                name: name,
                buildingName: buildingName,
                floor: floor,
                location: location,
                averageRating: averageRating,
                totalReviews: totalReviews,
                gender: gender,
                createdAt: createdAt,
                totalUses: totalUses
            )
            bathrooms.append(bathroom)
        }

        return bathrooms
    }

    func deleteReview(reviewId: String, bathroomId: String) async throws {
        // Get the bathroom document
        let bathroomDoc = try await db.collection("bathrooms").document(bathroomId).getDocument()
        guard var bathroom = try? await getBathroom(id: bathroomId) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bathroom not found"])
        }

        // Delete the review document
        try await db.collection("reviews").document(reviewId).delete()

        // Update bathroom rating
        let reviews = try await getReviews(forBathroomID: bathroomId)
        let newAverageRating = reviews.isEmpty ? 0.0 : reviews.map { $0.rating }.reduce(0, +) / Double(reviews.count)

        // Update bathroom document with new rating and review count
        try await db.collection("bathrooms").document(bathroomId).updateData([
            "averageRating": newAverageRating,
            "totalReviews": reviews.count
        ])
    }

    func getVisitHistory(userId: String) async throws -> [Visit] {
        let snapshot = try await db.collection("usage")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        var allVisits: [Visit] = []

        for document in snapshot.documents {
            let data = document.data()
            if let logs = data["logs"] as? [[String: Any]] {
                for log in logs {
                    let visit = Visit(
                        id: log["id"] as? String ?? UUID().uuidString,
                        userId: data["userId"] as? String ?? "",
                        bathroomId: log["bathroomId"] as? String ?? "",
                        timestamp: log["timestamp"] as? Timestamp ?? Timestamp(),
                        count: 1  // Each log represents one visit
                    )
                    allVisits.append(visit)
                }
            }
        }

        // Sort by timestamp descending (most recent first)
        allVisits.sort { $0.timestamp.dateValue() > $1.timestamp.dateValue() }

        return allVisits
    }

    func getUsage(id: String) async throws -> UsageCount? {
        let doc = try await db.collection("usage").document(id).getDocument()
        guard let data = doc.data() else { return nil }

        return UsageCount(
            id: doc.documentID,
            bathroomId: data["bathroomId"] as? String ?? "",
            userId: data["userId"] as? String ?? "",
            count: data["count"] as? Int ?? 0,
            lastUsed: data["lastUsed"] as? Timestamp ?? Timestamp(),
            logs: (data["logs"] as? [[String: Any]] ?? []).map { logData in
                UsageLog(
                    id: logData["id"] as? String ?? UUID().uuidString,
                    timestamp: logData["timestamp"] as? Timestamp ?? Timestamp(),
                    bathroomId: logData["bathroomId"] as? String ?? ""
                )
            }
        )
    }

    func getTotalUses(forUserId userEmail: String) async throws -> Int {
        let snapshot = try await db.collection("usage")
            .whereField("userId", isEqualTo: userEmail)
            .getDocuments()

        let totalUses = snapshot.documents.reduce(0) { sum, document in
            let data = document.data()
            let count = data["count"] as? Int ?? 1
            return sum + count
        }

        return totalUses
    }

    func updateUserPrivacySettings(userId: String, isPrivate: Bool, displayName: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "isProfilePrivate": isPrivate,
            "displayName": displayName
        ])
    }

    func getUserByEmail(email: String) async throws -> User? {
        print("Debug - Starting search for user with email: \(email)")
        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        let data = document.data()
        return User(
            id: document.documentID,
            authProvider: data["authProvider"] as? String ?? "",
            email: data["email"] as? String ?? "",
            fullName: data["fullName"] as? String ?? "",
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
            lastLoginAt: data["lastLoginAt"] as? Timestamp ?? Timestamp(),
            isProfilePrivate: data["isProfilePrivate"] as? Bool ?? false,
            displayName: data["displayName"] as? String ?? ""
        )

    }
}

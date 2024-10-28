//
//  UserProfile.swift
//  ucsb-bathrooms
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable {
    let id: String
    let fullName: String
    let email: String
    let authProvider: String
    let createdAt: Date
    let lastLoginAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fullName
        case email
        case authProvider
        case createdAt
        case lastLoginAt
    }

    // Helper method to convert Firestore data to UserProfile
    static func from(_ document: DocumentSnapshot) -> UserProfile? {
        guard let data = document.data() else { return nil }

        return UserProfile(
            id: document.documentID,
            fullName: data["fullName"] as? String ?? "",
            email: data["email"] as? String ?? "",
            authProvider: data["authProvider"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

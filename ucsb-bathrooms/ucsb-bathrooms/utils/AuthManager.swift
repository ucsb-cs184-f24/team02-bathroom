//
//  AuthManager.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/23/24.
//

import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import SwiftUI

class AuthManager {

    static let shared = AuthManager()

    // MARK: - Google Sign-In
    func signInWithGoogle(completion: @escaping (String, String, Bool) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                completion("No Name", "No Email", false)
                return
            }

            guard let signInResult = signInResult else {
                print("No sign-in result")
                completion("No Name", "No Email", false)
                return
            }

            let userFullName = signInResult.user.profile?.name ?? "No Name"
            let userEmail = signInResult.user.profile?.email ?? "No Email"

            // Create user data for Firestore
            let userData = FirestoreManager.User(
                id: signInResult.user.userID ?? UUID().uuidString,
                authProvider: "google",
                createdAt: Timestamp(),
                email: userEmail,
                fullName: userFullName,
                lastLoginAt: Timestamp(),
                reviews: []
            )

            // Save to Firestore
            Task {
                do {
                    // Check if user exists
                    if let _ = try await FirestoreManager.shared.getUser(withID: userData.id) {
                        // Update last login
                        try await FirestoreManager.shared.updateUser(userID: userData.id, data: [
                            "lastLoginAt": Timestamp()
                        ])
                    } else {
                        // Create new user
                        try await FirestoreManager.shared.addUser(userData)
                    }
                    completion(userFullName, userEmail, true)
                } catch {
                    print("Error saving user data: \(error.localizedDescription)")
                    completion(userFullName, userEmail, true)
                }
            }
        }
    }

    // MARK: - Apple Sign-In
    func handleAppleSignIn(_ authResults: ASAuthorization, completion: @escaping (String, String, Bool) -> Void) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            let fullName = appleIDCredential.fullName?.givenName ?? "Unknown"
            let email = appleIDCredential.email ?? "No Email"

            if let firstLoginEmail = appleIDCredential.email {
                UserDefaults.standard.set(firstLoginEmail, forKey: "userEmail")
            } else {
                let savedEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "No Email"
                UserDefaults.standard.set(savedEmail, forKey: "userEmail")
            }

            UserDefaults.standard.set(fullName, forKey: "userFullName")

            // Create user data for Firestore
            let userData = FirestoreManager.User(
                id: appleIDCredential.user,
                authProvider: "apple",
                createdAt: Timestamp(),
                email: email,
                fullName: fullName,
                lastLoginAt: Timestamp(),
                reviews: []
            )

            // Save to Firestore
            Task {
                do {
                    // Check if user exists
                    if let _ = try await FirestoreManager.shared.getUser(withID: userData.id) {
                        // Update last login
                        try await FirestoreManager.shared.updateUser(userID: userData.id, data: [
                            "lastLoginAt": Timestamp()
                        ])
                    } else {
                        // Create new user
                        try await FirestoreManager.shared.addUser(userData)
                    }
                    completion(fullName, email, true)
                } catch {
                    print("Error saving user data: \(error.localizedDescription)")
                    completion(fullName, email, true)
                }
            }
        } else {
            completion("No Name", "No Email", false)
        }
    }
}

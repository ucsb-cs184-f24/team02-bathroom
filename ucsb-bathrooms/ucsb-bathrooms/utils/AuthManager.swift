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

class AuthManager: ObservableObject {

    static let shared = AuthManager()

    private init() {}

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

            // Create the credential directly without optional binding
            let credential = GoogleAuthProvider.credential(
                withIDToken: signInResult.user.idToken?.tokenString ?? "",
                accessToken: signInResult.user.accessToken.tokenString
            )

            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                    completion("No Name", "No Email", false)
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    completion("No Name", "No Email", false)
                    return
                }

                // Create user data for Firestore using Firebase UID
                let userData = FirestoreManager.User(
                    id: firebaseUser.uid,  // Use Firebase UID
                    authProvider: "google",
                    email: userEmail,
                    fullName: userFullName,
                    createdAt: Timestamp(),
                    lastLoginAt: Timestamp(),
                    isProfilePrivate: false,
                    displayName: userFullName
                )

                // Save to Firestore
                Task {
                    do {
                        if let _ = try await FirestoreManager.shared.getUser(withID: firebaseUser.uid) {
                            // Update last login
                            try await FirestoreManager.shared.updateUserLastLogin(userID: firebaseUser.uid)
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
    }

    // MARK: - Apple Sign-In
    func handleAppleSignIn(_ authResults: ASAuthorization, completion: @escaping (String, String, Bool) -> Void) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName?.givenName ?? "Unknown"
            let email = appleIDCredential.email ?? "No Email"

            // Save email to UserDefaults if it's the first login
            if let firstLoginEmail = appleIDCredential.email {
                UserDefaults.standard.set(firstLoginEmail, forKey: "userEmail")
            } else {
                let savedEmail = UserDefaults.standard.string(forKey: "userEmail") ?? "No Email"
                UserDefaults.standard.set(savedEmail, forKey: "userEmail")
            }

            UserDefaults.standard.set(fullName, forKey: "userFullName")

            // Create user data for Firestore using Firebase UID
            let userData = FirestoreManager.User(
                id: userID,  // Use Firebase UID
                authProvider: "apple",
                email: email,
                fullName: fullName,
                createdAt: Timestamp(),
                lastLoginAt: Timestamp(),
                isProfilePrivate: false,
                displayName: fullName
            )

            // Save to Firestore
            Task {
                do {
                    if let _ = try await FirestoreManager.shared.getUser(withID: userID) {
                        // Update last login
                        try await FirestoreManager.shared.updateUserLastLogin(userID: userID)
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

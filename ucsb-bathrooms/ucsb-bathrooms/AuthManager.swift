//
//  AuthManager.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/23/24.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices
import SwiftUI

class AuthManager {
    static let shared = AuthManager()
    private let db = Firestore.firestore()

    // MARK: - Save User Profile
    private func saveUserProfile(id: String, fullName: String, email: String, provider: String) {
        let userRef = db.collection("users").document(id)

        let userData: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "authProvider": provider,
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]

        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                userRef.updateData([
                    "lastLoginAt": FieldValue.serverTimestamp()
                ])
            } else {
                userRef.setData(userData)
            }
        }
    }

    // MARK: - Google Sign-In
    func signInWithGoogle(completion: @escaping (String, String, Bool) -> Void) {
        guard (FirebaseApp.app()?.options.clientID) != nil else { return }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
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

            // Store user data
            UserDefaults.standard.set(userFullName, forKey: "userFullName")
            UserDefaults.standard.set(userEmail, forKey: "userEmail")

            // Get Firebase credential
            guard let idToken = signInResult.user.idToken?.tokenString else {
                completion("No Name", "No Email", false)
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: signInResult.user.accessToken.tokenString
            )

            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                if error != nil {
                    completion("No Name", "No Email", false)
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    completion("No Name", "No Email", false)
                    return
                }

                // Save to Firestore
                self?.saveUserProfile(
                    id: firebaseUser.uid,
                    fullName: userFullName,
                    email: userEmail,
                    provider: "google"
                )

                completion(userFullName, userEmail, true)
            }
        }
    }

    // MARK: - Apple Sign-In
    func handleAppleSignIn(_ authResults: ASAuthorization, completion: @escaping (String, String, Bool) -> Void) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                completion("No Name", "No Email", false)
                return
            }

            // Improved name handling
            let fullName = appleIDCredential.fullName?.givenName ?? "Unknown"
            var email = "No Email"

            // Improved email handling with persistence
            if let firstLoginEmail = appleIDCredential.email {
                email = firstLoginEmail
                UserDefaults.standard.set(firstLoginEmail, forKey: "userEmail")
            } else {
                email = UserDefaults.standard.string(forKey: "userEmail") ?? "No Email"
            }

            // Create Firebase credential
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: identityTokenString,
                rawNonce: ""
            )

            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
                if error != nil {
                    completion("No Name", "No Email", false)
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    completion("No Name", "No Email", false)
                    return
                }

                // Store user data
                UserDefaults.standard.set(fullName, forKey: "userFullName")
                UserDefaults.standard.set(email, forKey: "userEmail")

                // Save to Firestore
                self?.saveUserProfile(
                    id: firebaseUser.uid,
                    fullName: fullName,
                    email: email,
                    provider: "apple"
                )

                completion(fullName, email, true)
            }
        } else {
            completion("No Name", "No Email", false)
        }
    }
}

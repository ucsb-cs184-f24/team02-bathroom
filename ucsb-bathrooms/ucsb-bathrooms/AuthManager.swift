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
        // guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // let config = GIDConfiguration(clientID: clientID)

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
            
            completion(userFullName, userEmail, true)
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

            completion(fullName, email, true)
        } else {
            completion("No Name", "No Email", false)
        }
    }
}

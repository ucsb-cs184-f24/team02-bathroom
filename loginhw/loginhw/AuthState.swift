//
//  AuthState.swift
//  loginhw
//
//  Created by Zheli Chen on 10/23/24.
//


import SwiftUI
import FirebaseAuth
import Firebase

class AuthState: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var currentUser: UserModel? = nil

    init() {
        self.isSignedIn = Auth.auth().currentUser != nil
        self.currentUser = AuthState.fetchUserModel(from: Auth.auth().currentUser)
        
        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isSignedIn = user != nil
                self.currentUser = AuthState.fetchUserModel(from: user)
            }
        }
    }
    
    private static func fetchUserModel(from user: User?) -> UserModel? {
        guard let user = user else { return nil }
        return UserModel(
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoURL: user.photoURL?.absoluteString
        )
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
            self.currentUser = nil
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

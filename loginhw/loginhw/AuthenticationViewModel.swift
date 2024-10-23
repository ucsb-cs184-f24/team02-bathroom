//
//  AuthenticationViewModel.swift
//  loginhw
//
//  Created by Zheli Chen on 10/22/24.
//

import Foundation

@MainActor
final class AuthenticationViewModel: ObservableObject {
        
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let _ = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
    }
}

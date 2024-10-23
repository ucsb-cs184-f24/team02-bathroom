//
//  AuthenticationView.swift
//  loginhw
//
//  Created by Zheli Chen on 10/22/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

struct AuthenticationView: View {
    
    @StateObject private var viewModel = AuthenticationViewModel()
    @EnvironmentObject var authState: AuthState
    
    var body: some View {
        VStack {
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                Task {
                    do {
                        try await viewModel.signInGoogle()
                    } catch {
                        print("Google Sign-In Error: \(error)")
                    }
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Sign In")
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AuthenticationView()
                .environmentObject(AuthState())
        }
    }
}

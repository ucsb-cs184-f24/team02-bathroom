//
//  LandingPageView.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/22/24.
//

import SwiftUI
import AuthenticationServices

struct LandingPageView: View {
    @Binding var isAuthenticated: Bool
    @Binding var userFullName: String
    @Binding var userEmail: String

    var body: some View {
        ZStack {

            LinearGradient(
                gradient: Gradient(colors: [Color("gold"), Color("navy-blue")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                
                Image("ucsb-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .shadow(radius: 10)
                    .opacity(0.9)
                    .transition(.opacity)
                    .padding(.top, 80)
                
                Text("Restrooms")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                    .transition(.slide)
                
                Text("Find the best restrooms on campus easily.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Google Sign-In Button
                Button(action: {
                    AuthManager.shared.signInWithGoogle { fullName, email, success in
                        if success {
                            self.userFullName = fullName
                            self.userEmail = email
                            self.isAuthenticated = true
                        }
                    }
                }) {
                    HStack {
                        Image("google-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Sign in with Google")
                            .font(.system(size: 18, weight: .medium))
                            .padding(.leading, 10) 
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(24)
                }
                .frame(height: 50)
                .padding(.horizontal, 40)
                .shadow(radius: 5)
                
                // Apple Sign-In Button
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            AuthManager.shared.handleAppleSignIn(authResults) { fullName, email, success in
                                if success {
                                    self.userFullName = fullName
                                    self.userEmail = email
                                    self.isAuthenticated = true
                                }
                            }
                        case .failure(let error):
                            print("Apple Sign-In authorization failed: \(error.localizedDescription)")
                        }
                    }
                )
                .frame(height: 50)
                .cornerRadius(24)
                .padding(.horizontal, 40)
                .shadow(radius: 5)
                
                Text("Sign in to access restroom locations.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.7))
                
                Spacer()
            }
        }
    }
}

#Preview {
    LandingPageView(isAuthenticated: .constant(false), userFullName: .constant(""), userEmail: .constant(""))
}

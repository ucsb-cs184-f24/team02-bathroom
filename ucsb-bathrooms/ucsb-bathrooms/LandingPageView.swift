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
            
            VStack(spacing: 40) {
                
                    Image("ucsb-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .padding(.top, 80)
                        .shadow(radius: 10)
                        .opacity(0.9)
                        .transition(.opacity)
                    
                    Text("Restrooms")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white)
                        .shadow(radius: 5)
                        .padding(.top, 16)
                        .transition(.slide)
                
                Text("Find the best restrooms on campus easily.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
                    .padding(.horizontal, 32)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Apple Sign-In Button
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            handleAuthentication(authResults)
                            isAuthenticated = true
                        case .failure(let error):
                            print("Authorization failed: \(error.localizedDescription)")
                            isAuthenticated = false
                        }
                    }
                )
                .frame(height: 50)
                .cornerRadius(10)
                .padding(.horizontal, 40)
                .shadow(radius: 5)
                
                Text("Sign in to access restroom locations.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.bottom, 50)
        }
    }
    
    func handleAuthentication(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            let fullName = appleIDCredential.fullName?.givenName ?? "Unknown"
            let email = appleIDCredential.email ?? "No email provided"
            
            userFullName = fullName
            userEmail = email
            
            UserDefaults.standard.set(fullName, forKey: "userFullName")
            UserDefaults.standard.set(email, forKey: "userEmail")
        }
    }
}

#Preview {
    LandingPageView(isAuthenticated: .constant(false), userFullName: .constant(""), userEmail: .constant(""))
}

import SwiftUI

struct ProfilePageView: View {
    @Binding var userFullName: String
    @Binding var userEmail: String
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 50)
            
            Spacer()
            
            Text("Name: \(userFullName)")
                .font(.system(size: 24, weight: .medium))
                .padding(.horizontal, 16)
            
            Text("Email: \(userEmail)")
                .font(.system(size: 20))
                .padding(.horizontal, 16)
            
            Spacer()
            
            // Sign Out Button
            Button(action: signOut) {
                Text("Sign Out")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
            }
            .padding(.horizontal, 16)
            
        }
        .padding()
    }
    
    func signOut() {
        userFullName = ""
        userEmail = ""
        isAuthenticated = false

        UserDefaults.standard.removeObject(forKey: "userFullName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }
}

#Preview {
    ProfilePageView(userFullName: .constant("Test User"), userEmail: .constant("test@example.com"), isAuthenticated: .constant(true))
}

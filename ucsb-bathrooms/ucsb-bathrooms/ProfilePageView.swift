//
//  ProfilePageView.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/22/24.
//

import SwiftUI
import Firebase

struct ProfilePageView: View {
    @Binding var userFullName: String
    @Binding var userEmail: String
    @Binding var isAuthenticated: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("Profile")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top, 30)
                    .foregroundColor(Color.navyBlue)
                
                Button(action: { profilePictureTapped() }) {
                    Image("profile-pic")
                        .resizable()
                        .frame(width: 175, height: 175)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.navyBlue, lineWidth: 2))
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Name: \(userFullName)")
                    .font(.system(size: 24, weight: .medium))
                    .padding(.horizontal, 16)
                    .foregroundColor(Color.navyBlue)
                
                Text("Email: \(userEmail)")
                    .font(.system(size: 20))
                    .padding(.horizontal, 16)
                    .foregroundColor(Color.navyBlue)
                
                Divider()
                    .padding(.horizontal)
                
                Text("Favorites")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color.navyBlue)
                    .padding(.bottom, 5)
                
                Divider()
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("- Placeholder Bathroom")
                            .font(.system(size: 20))
                            .padding(.horizontal, 60)
                        Text("- Placeholder Bathroom")
                            .font(.system(size: 20))
                            .padding(.horizontal, 60)
                        Text("- Placeholder Bathroom")
                            .font(.system(size: 20))
                            .padding(.horizontal, 60)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }.frame(maxWidth: .infinity)
                
                Divider()
                    .padding(.horizontal)
                
                Spacer()
                
                Button(action: signOut) {
                    Text("Sign Out")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.navyBlue)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
                .padding(.horizontal, 16)
            }
            .padding()
            .navigationBarItems(trailing:
                Button(action: openSettings) {
                    Image(systemName: "gear")
                        .font(.title)
                        .foregroundColor(.navyBlue)
            }.padding(.horizontal, 5)
            )
        }
    }
    
    func profilePictureTapped() {
        // Add action here, e.g., navigate to a new screen or open an image picker
    }
    
    func signOut() {
        userFullName = ""
        userEmail = ""
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "userFullName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
    }

    func openSettings() {
        // Add action here, e.g., navigate to a settings view
    }
}

#Preview {
    ProfilePageView(userFullName: .constant("Test User"), userEmail: .constant("test@example.com"), isAuthenticated: .constant(true))
}

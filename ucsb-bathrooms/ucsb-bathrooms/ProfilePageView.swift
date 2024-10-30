//
//  ProfilePageView.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/22/24.
//

import SwiftUI

struct ProfilePageView: View {
    @Binding var userFullName: String
    @Binding var userEmail: String
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 30)
            
            Image("profile-pic")
                .resizable()
                .frame(width: 175, height: 175)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 1))
        
            Text("Name: \(userFullName)")
                .font(.system(size: 24, weight: .medium))
                .padding(.horizontal, 16)
            
            Text("Email: \(userEmail)")
                .font(.system(size: 20))
                .padding(.horizontal, 16)
            
            //Favourties
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Text("Favorites")
                .font(.system(size: 26, weight: .bold))
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) { // Adjust spacing as needed
                    HStack(alignment: .top) {
                        Text("•") // Dot symbol
                            .font(.system(size: 20))
                            .padding(.trailing, 4) // Space between dot and text
                        Text("Placeholder Bathroom")
                            .font(.system(size: 20))
                            .padding(.horizontal, 16)
                    }
                    // Add more list items here by duplicating the HStack
                }
                .padding()
            }
            
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

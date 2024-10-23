//
//  ProfileView.swift
//  loginhw
//
//  Created by Zheli Chen on 10/23/24.
//


// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authState.currentUser {
                    // Display Profile Picture
                    if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            case .failure:
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    // Display Display Name
                    if let displayName = user.displayName {
                        Text("Name: \(displayName)")
                            .font(.title2)
                            .padding(.top, 10)
                    }
                    
                    // Display Email
                    if let email = user.email {
                        Text("Email: \(email)")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("No user is currently signed in.")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                // Sign Out Button
                Button(action: {
                    authState.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthState())
    }
}

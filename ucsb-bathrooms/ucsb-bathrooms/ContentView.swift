//
//  ContentView.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/9/24.
//
import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    @Environment(AuthController.self) private var authController
    @State private var showTabBarView = false

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "person.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                
                if let user = Auth.auth().currentUser {
                    Text("Hello, \(user.displayName ?? user.email ?? "User")!")
                }
                
                Button("Explore the Bathrooms") {
                    showTabBarView = true
                }
                .padding()
            }
            .padding()
            .navigationDestination(isPresented: $showTabBarView) {
                TabBarView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(AuthController())
}

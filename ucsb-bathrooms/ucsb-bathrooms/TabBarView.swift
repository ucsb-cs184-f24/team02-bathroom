import SwiftUI
import FirebaseAuth

struct TabBarView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            MapView() // First tab content
                .tabItem {
                    Image(systemName: self.selectedTab == 0 ? "map.fill" : "map")
                    Text("Map")
                }
                .tag(0)
            
            PlaceholderView() // Second tab content
                .tabItem {
                    Image(systemName: self.selectedTab == 1 ? "star.fill" : "star")
                    Text("Placeholder")
                }
                .tag(1)

            AccountView() // Third tab content
                .tabItem {
                    Image(systemName: self.selectedTab == 2 ? "person.fill" : "person")
                    Text("My Account")
                }
                .tag(2)
        }
    }
}

struct MapView: View {
    var body: some View {
        BathroomMapView()
    }
}

struct PlaceholderView: View {
    var body: some View {
        Text("Bathroom Leaderboard")
            .font(.largeTitle)
            .padding()
    }
}

struct AccountView: View {
    @Environment(AuthController.self) private var authController
    @State private var showSignInPage = false

    var body: some View {
        VStack {
            if let user = Auth.auth().currentUser {
                Text("Welcome, \(user.displayName ?? user.email ?? "User")!")
            } else {
                Text("No user is signed in.")
            }

            Button("Sign out") {
                signOut()
            }
            .padding()
        }
        .padding()
    }

    func signOut() {
        do {
            try authController.signOut()
            showSignInPage = true // Optionally, navigate back to sign-in screen
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    TabBarView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(AuthController())
}

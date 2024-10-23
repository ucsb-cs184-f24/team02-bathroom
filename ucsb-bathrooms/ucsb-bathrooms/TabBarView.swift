import SwiftUI

struct TabBarView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            ContentView()
                .tabItem {
                    if self.selectedTab == 0 {
                        Image(systemName: "map")
                    } else {
                        Image(systemName: "map.fill")
                    }
                    Text("Map")
                }
                .tag(0)
            
            ContentView()
                .tabItem {
                    if self.selectedTab == 1 {
                        Image(systemName: "star")
                    } else {
                        Image(systemName: "star.fill")
                    }
                    Text("placeholder")
                }
                .tag(1)

            ContentView()
                .tabItem {
                    if self.selectedTab == 1 {
                        Image(systemName: "person")
                    } else {
                        Image(systemName: "person.fill")
                    }
                    Text("My Account")
                }
                .tag(2)
        }
    }
}

#Preview {
    TabBarView()
}

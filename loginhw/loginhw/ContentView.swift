//
//  ContentView.swift
//  loginhw
//
//  Created by Zheli Chen on 10/22/24.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthState())
    }
}

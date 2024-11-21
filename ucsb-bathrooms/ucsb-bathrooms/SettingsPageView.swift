//
//  SettingsPageView.swift
//  ucsb-bathrooms
//
//  Created by Kendrick Lee on 11/20/2024.
//

import SwiftUI

struct SettingsPageView: View {
    @State private var searchRange: Double = 5.0
    @State private var notificationsEnabled: Bool = true
    @State private var darkModeEnabled: Bool = false

    var body: some View {
        Form {
            // Section for Search Range
            Section(header: Text("Search Settings")) {
                VStack(alignment: .leading) {
                    Text("Search Range: \(String(format: "%.1f", searchRange)) miles")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Slider(value: $searchRange, in: 1...20, step: 0.5) {
                        Text("Search Range")
                    }
                }
                .padding(.vertical)
            }

            // Section for Notifications
            Section(header: Text("Notifications")) {
                Toggle(isOn: $notificationsEnabled) {
                    Text("Enable Notifications")
                }
            }

            // Section for Appearance
            Section(header: Text("Appearance")) {
                Toggle(isOn: $darkModeEnabled) {
                    Text("Enable Dark Mode")
                }
            }

            // Placeholder Section
            Section(header: Text("More Settings"), footer: Text("More customization options coming soon!")) {
                Text("Setting 1")
                Text("Setting 2")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsPageView()
}

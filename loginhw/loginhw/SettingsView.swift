//
//  SettingsView.swift
//  loginhw
//
//  Created by Zheli Chen on 10/23/24.
//


// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Hello World")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

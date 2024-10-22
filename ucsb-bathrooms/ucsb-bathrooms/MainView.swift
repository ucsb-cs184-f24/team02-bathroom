//
//  MainView.swift
//  ucsb-bathrooms
//
//  Created by Julissa Guan on 10/22/24.
//

import SwiftUI

struct MainView: View {
    @Environment(AuthController.self) private var authController

    var body: some View {
        Group {
            switch authController.authState {
            case .undefined:
                ProgressView()
            case .authenticated:
                ContentView()
            case .notAuthenticated:
                AuthView()
            }
        }
        .task {
            await authController.startListeningToAuthState()
        }
    }
}

#Preview {
    MainView()
}

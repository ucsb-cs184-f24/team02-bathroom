//
//  loginhwApp.swift
//  loginhw
//
//  Created by Zheli Chen on 10/22/24.
//

import SwiftUI
import Firebase

@main
struct loginhwApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            if authState.isSignedIn {
                ContentView()
                    .environmentObject(authState)
            } else {
                AuthenticationView()
                    .environmentObject(authState)
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        return true
    }

}

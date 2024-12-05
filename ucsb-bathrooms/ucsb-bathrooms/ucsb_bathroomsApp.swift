//
//  ucsb_bathroomsApp.swift
//  ucsb-bathrooms
//
//  Created by Luis Bravo on 10/9/24.
//

import SwiftUI
import SwiftData
import FirebaseCore
import Firebase
import FirebaseStorage
import FirebaseFirestore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct ucsb_bathroomsApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate


  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}

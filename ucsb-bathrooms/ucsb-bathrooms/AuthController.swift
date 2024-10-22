//
//  AuthController.swift
//  ucsb-bathrooms
//
//  Created by Julissa Guan on 10/22/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@Observable
class AuthController: ObservableObject {
    var authState: AuthState = .undefined

    func startListeningToAuthState() async {
        Auth.auth().addStateDidChangeListener{ _, user in
            self.authState = user != nil ? .authenticated : .notAuthenticated
        }
    }

    @MainActor
    func signIn() async throws {
        guard let rootViewController = UIApplication.shared.firstKeyWindow?.rootViewController else{ return }
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = result.user.idToken?.tokenString else { return }
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.windows
            .first(where: \.isKeyWindow)
    }
}

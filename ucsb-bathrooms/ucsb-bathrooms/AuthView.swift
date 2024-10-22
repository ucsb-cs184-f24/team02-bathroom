//
//  AuthView.swift
//  ucsb-bathrooms
//
//  Created by Julissa Guan on 10/22/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift


struct AuthView: View {
    @Environment(AuthController.self)private var authController
    
    var body: some View{
        VStack {
            Spacer()
            GoogleSignInButton(scheme:.dark, style:.standard, state: .normal){
                signIn()
            }
        }
        .padding()
    }
    
    @MainActor
    func signIn(){
        Task {
            do {
                try await authController.signIn()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    AuthView()
}

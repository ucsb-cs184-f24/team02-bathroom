//
//  UserModel.swift
//  loginhw
//
//  Created by Zheli Chen on 10/23/24.
//


import Foundation

struct UserModel: Identifiable {
    let id: String
    let displayName: String?
    let email: String?
    let photoURL: String?
    
    init(uid: String, displayName: String?, email: String?, photoURL: String?) {
        self.id = uid
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
    }
}

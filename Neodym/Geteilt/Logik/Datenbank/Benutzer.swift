//
//  Benutzer.swift
//  Neodym
//
//  Created by Max Eckstein on 30.11.23.
//

import SwiftUI
import FirebaseAuth

@MainActor class Benutzer: ObservableObject {
    
    init() {
        if let user = Auth.auth().currentUser {
            asyncInit(user)
        }
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user {
                self.asyncInit(user)
            }
        }
    }
    
    func asyncInit(_ user: User){
        Task {
            self.name = user.displayName ?? "Fehler"
            self.bild = await StorageManager.ladeProfilbild()
            self.premium = true
            self.email = user.email
        }
    }
    
    @Published var name: String = "Fehler"
    @Published var email: String? = nil
    @Published var bild: UIImage? = nil
    @Published var premium: Bool? = true
}

extension UserDefaults {
    @objc dynamic var name: String? {
        return string(forKey: "name")
    }
}

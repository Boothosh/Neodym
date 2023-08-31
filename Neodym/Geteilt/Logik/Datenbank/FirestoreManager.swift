//
//  FirestoreManager.swift
//  Neodym
//
//  Created by Max Eckstein on 16.07.23.
//

import FirebaseFirestore

struct FirestoreManager {
    
    static func ladeText(fuer element: Element) async -> String? {
        do {
            let dokument = try await Firestore.firestore().document("/elemente/\(element.name)").getDocument()
            return dokument.data()?["text"] as? String
        } catch {
            print(error)
            return "Kein weiterführender Text verfügbar."
        }
    }
    
}

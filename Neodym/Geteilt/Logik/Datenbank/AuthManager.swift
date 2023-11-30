//
//  AuthManager.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions

struct AuthManager {
    
    /// Gibt die Fehlerbeschreibung zurück, falls es einen gab
    static func abmelden(kontoLoeschen: Bool = false) async -> String? {
        guard let user = Auth.auth().currentUser else { return "Benutzer ist nicht korrekt angemeldet." }
        do {
            if user.isAnonymous || kontoLoeschen {
                if let lizenz = UserDefaults.standard.string(forKey: "lizenz") {
                    _ = try await Functions.functions().httpsCallable("gebeLizenzFrei").call(["text": lizenz])
                }
                try await user.delete()
            } else {
                try Auth.auth().signOut()
            }
        } catch {
            print(error)
            return error.localizedDescription
        }
        return nil
    }
    
    /// Gibt die Fehlerbeschreibung zurück, falls es einen gab
    static func aendereNamen(zu name: String) async -> String? {
        let nameTrimmed = name.trimmingCharacters(in: [" "])
        guard nameTrimmed.count > 0 else { return "Das Namensfeld ist Leer oder enthält nur Leerzeichen." }
        guard let benutzer = Auth.auth().currentUser else { return "Benutzer ist nicht korrekt angemeldet." }
        do {
            let changeRequest = benutzer.createProfileChangeRequest()
            changeRequest.displayName = nameTrimmed
            try await changeRequest.commitChanges()
            return nil
        } catch {
            print(error)
            return error.localizedDescription
        }
    }
    
    @MainActor
    /// Gibt die Fehlerbeschreibung zurück, falls es einen gab
    static func registrieren(mitLizenz lizenz: String? = nil, email: String? = nil, passwort: String? = nil, vorname: String, benutzer: Benutzer) async -> String? {
        do {
            if let lizenz {
                let ergebnis = try await Functions.functions().httpsCallable("validiereLizenz").call(["text": lizenz]).data as? String ?? "Funktion ist fehlgeschlagen"
                if ergebnis == "Inaktiv" {
                    try await Auth.auth().signInAnonymously()
                    UserDefaults.standard.setValue(lizenz, forKey: "lizenz")
                } else {
                    if ergebnis == "Aktiv" {
                        return "Diese Lizenz ist schon aktiviert worden."
                    } else if ergebnis == "Invalide"{
                        return "Diese Lizenz konnte nicht gefunden werden."
                    } else {
                        return ergebnis
                    }
                }
            } else {
                guard let email = email, let passwort = passwort else { return "Fehler bei der Übergabe von Argumenten." }
                try await Auth.auth().createUser(withEmail: email, password: passwort)
            }
            guard let benutzer = Auth.auth().currentUser else { return "Benutzer ist nicht korrekt angemeldet." }
            try await Firestore.firestore().document("benutzer/\(benutzer.uid)").setData(["erstellungsDatum" : Date()])
        } catch {
            print(error)
            return error.localizedDescription
        }
        benutzer.name = vorname
        return await aendereNamen(zu: vorname)
    }
    
    /// Gibt die Fehlerbeschreibung zurück, falls es einen gab
    static func anmelden(email: String, passwort: String) async -> String? {
        do {
            try await Auth.auth().signIn(withEmail: email, password: passwort)
        } catch {
            print(error)
            return error.localizedDescription
        }
        return nil
    }
    
}

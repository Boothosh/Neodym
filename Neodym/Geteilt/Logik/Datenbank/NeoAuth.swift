//
//  NeoAuth.swift
//  Neodym
//
//  Created by Max Eckstein on 30.11.23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFunctions
import FirebaseFirestore
import FirebaseFirestoreSwift
import Observation

@Observable class NeoAuth {

    var verifiziert: Bool? = nil
    var angemeldet: Bool? = nil
    var verifizierteEmail: Bool? = nil
    
    // Parameter
    var email: String?
    var id: String?
    var lizenzSchluessel: String?
    var lizenzEndDatum: Date?
    
    func delayedInit() async {
        guard let user = Auth.auth().currentUser else {
            angemeldet = false
            verifiziert = false
            return
        }
        angemeldet = true
        verifizierteEmail = Auth.auth().currentUser?.isEmailVerified
        do {
            if try await pruefeIdentitaet("lehrer") {
                verifiziert = true
            } else {
                verifiziert = try await pruefeIdentitaet("schueler")
            }
        } catch {
            print(error)
            do {
                verifiziert = try await pruefeIdentitaet("schueler")
            } catch {
                print(error)
            }
        }
        print("[NeoAuth]: delayedInit() abgeschlossen")
    }
    
    func pruefeIdentitaet(_ fuer: String) async throws -> Bool {
        guard let benutzer = Auth.auth().currentUser else { return false }
        self.id = benutzer.uid
        if fuer == "lehrer", let mail = benutzer.email {
            email = mail
            if !benutzer.isEmailVerified {
                try await Auth.auth().currentUser?.reload()
                if !benutzer.isEmailVerified {
                    return false
                }
            }
        }
        func leseDok(_ dok: [String: Any]) -> Bool {
            if fuer == "schueler" {
                self.lizenzSchluessel   = dok["lizenz"] as? String
                self.lizenzEndDatum     = (dok["endDatum"] as? Timestamp)?.dateValue()
                return lizenzEndDatum ?? Date() > Date()
            } else {
                return dok["verifiziert"] as? Bool ?? false
            }
        }
        do {
            let doc = try await Firestore.firestore().document("/\(fuer)/\(benutzer.uid)").getDocument(source: .cache)
            guard doc.exists, let data = doc.data() else { throw Fehler.benutzerAkteNichtGefunden }
            do {
                let doc = try await Firestore.firestore().document("/\(fuer)/\(benutzer.uid)").getDocument(source: .server)
                guard doc.exists, let data = doc.data() else { throw Fehler.benutzerAkteNichtGefunden }
                return leseDok(data)
            } catch {
                return leseDok(data)
            }
        } catch {
            let doc = try await Firestore.firestore().document("/\(fuer)/\(benutzer.uid)").getDocument(source: .server)
            guard doc.exists, let data = doc.data() else { throw Fehler.benutzerAkteNichtGefunden }
            return leseDok(data)
        }
    }
    
    // Gibt die jeweilige Identifikation der Person aus
    var identifikation: String? {
        lizenzSchluessel ?? email
    }
    
    /// Für Lehrer
    func anmelden(email: String, passwort: String) async throws {
        guard !(angemeldet == true) else { throw Fehler.angemeldet }
        try await Auth.auth().signIn(withEmail: email, password: passwort)
        self.angemeldet = true
        verifiziert = try await pruefeIdentitaet("lehrer")
        Task.detached(priority: .background) {
            // Noch Schueler Dokument laden
            sleep(5)
            guard let benutzer = Auth.auth().currentUser else { return }
            let _ = try await Firestore.firestore().document("/lehrer/\(benutzer.uid)").getDocument(source: .server)
        }
    }
    
    /// Für Lehrer
    func registrierenMitAnmeldedaten(email: String, passwort: String) async throws {
        guard !(angemeldet == true) else { throw Fehler.angemeldet }
        try await Auth.auth().createUser(withEmail: email, password: passwort)
        // Werte auf lokale NeoAuth Klasse übertragen
        guard let user = Auth.auth().currentUser else { throw Fehler.undefiniert }
        self.id             = user.uid
        self.email          = email
        self.angemeldet     = true
        try await sendeVerifikationsMail()
        Task.detached(priority: .background) {
            // Noch Schueler Dokument laden
            sleep(5)
            let _ = try await Firestore.firestore().document("/lehrer/\(user.uid)").getDocument(source: .server)
        }
    }
    
    /// Neuen Schüler registrieren
    func registrierenMitLizenz(lizenz: String) async throws {
        guard !(angemeldet == true) else { throw Fehler.angemeldet }
        let ergebnis = try await Functions.functions().httpsCallable("validiereLizenz").call(["lizenz": lizenz]).data
        guard let ergebnis = ergebnis as? Int else {
            if let ergebnis = ergebnis as? String {
                if ergebnis == "Aktiv" {
                    print("Schon aktiv")
                    throw Fehler.lizenzSchonAktiv
                } else {
                    print("Nicht gefunden?")
                    throw Fehler.lizenzNichtGefunden
                }
            } else {
                throw Fehler.undefiniert
            }
        }
        try await Auth.auth().signInAnonymously()
        let _ = try await Functions.functions().httpsCallable("weiseLizenzZu").call(["lizenz": lizenz])
        // Werte auf lokale NeoAuth Klasse übertragen
        guard let user = Auth.auth().currentUser else { throw Fehler.undefiniert }
        self.id                 = user.uid
        self.lizenzSchluessel   = lizenz
        self.lizenzEndDatum     = Date(timeIntervalSince1970: TimeInterval(ergebnis/1000))
        self.angemeldet         = true
        self.verifiziert        = true
        
        Task.detached(priority: .background) {
            // Noch Schueler Dokument laden
            sleep(5)
            let _ = try await Firestore.firestore().document("/schueler/\(user.uid)").getDocument(source: .server)
        }
    }
    
    func sendeVerifikationsMail() async throws {
        guard let user = Auth.auth().currentUser else { throw Fehler.abgemeldet }
        try await user.sendEmailVerification()
    }
    
    /// Aktuellen Benutzer abmelden
    /// Wenn `loeschen` wahr ist, so wird der Account unwiederruflich gelöscht
    func abmelden(loeschen: Bool = false) async throws {
        guard (angemeldet == true), let user = Auth.auth().currentUser else { throw Fehler.abgemeldet }
        
        if email == nil || loeschen {
            try await user.delete()
        } else {
            try Auth.auth().signOut()
        }
        
        // Werte zurücksetzen
        self.email              = nil
        self.lizenzSchluessel   = nil
        self.lizenzEndDatum     = nil
        
        // Abmelden
        self.verifiziert = false
        self.angemeldet = false
        self.verifizierteEmail = false
    }
    
    /// Passwort von dem Konto mit der übergebenen E-Mail zurücksetzen.
    /// Gibt mögliche Errors, die bei `sendPasswordReset()` entstehen können, weiter.
    func passwortZuruecksetzen(_ email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
        
    enum Fehler: LocalizedError {
        case abgemeldet
        case angemeldet
        case lizenzSchonAktiv
        case lizenzNichtGefunden
        case benutzerAkteNichtGefunden
        case undefiniert
        public var errorDescription: String? {
            return "x"
        }
    }
    
}

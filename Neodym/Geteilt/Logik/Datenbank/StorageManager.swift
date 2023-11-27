//
//  StorageManager.swift
//  Neodym
//
//  Created by Max Eckstein on 15.07.23.
//

import FirebaseStorage
import FirebaseAuth
import UIKit
import SceneKit

struct StorageManager {
    
    // MARK: Helper Funktionen
    
    // MARK: Bild aus der Datenbank
    private static func ladeBildAusDatenbank(_ pfad: URL) async -> UIImage? {
        let maxGroesse: Int64 = 10000000 // Maximale Dateigröße ist 10MB
        do {
            let referenz = try Storage.storage().reference(for: pfad)
            return await withCheckedContinuation { continuation in
                referenz.getData(maxSize: maxGroesse) { data, error in
                    if let error = error {
                        continuation.resume(returning: nil)
                        print(error)
                    } else {
                        guard let data = data else { continuation.resume(returning: nil); return }
                        continuation.resume(returning: UIImage(data: data))
                    }
                }
            }
        } catch {
            print(error)
            return nil
        }
    }
    
    // MARK: Lese lokales Bild aus
    
    private static func leseLokalesBildAus(_ teilPfad: String) -> UIImage? {
        guard let urlPrefix = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let lokaleURL = urlPrefix.appendingPathComponent("\(teilPfad).jpg")
        if FileManager.default.fileExists(atPath: lokaleURL.path) {
            return UIImage(contentsOfFile: lokaleURL.path())
        } else {
            return nil
        }
    }
    
    static func speichereProfilbild(_ bild: Data) async -> String? {
        guard let benutzer = Auth.auth().currentUser else { return "Benutzer ist nicht korrekt angemeldet." }
        let referenz = Storage.storage().reference().child("profilbilder/\(benutzer.uid).jpg")
        do {
            let _ = try await referenz.putDataAsync(bild)
            let changeRequest = benutzer.createProfileChangeRequest()
            changeRequest.photoURL = URL(string: "gs://neo-datenbank.appspot.com/profilbilder/\(benutzer.uid).jpg")
            try await changeRequest.commitChanges()
        } catch {
            print(error)
            return error.localizedDescription
        }
        return nil
    }
    
    /// Gibt, im Falle dass noch kein Bild konfiguriert wurde, ein Standart-Bild zurück
    /// Gibt nil zurück, falls kein Bild geladen werden konnte
    static func ladeProfilbild() async -> UIImage? {
        guard let photoURL = Auth.auth().currentUser?.photoURL, let bild = await ladeBildAusDatenbank(photoURL) else {
            return UIImage(named: "Mann")
        }
        return bild
    }
    
    static func ladeBildFuer(element: Element) async -> UIImage? {
        guard let photoURL = URL(string: "gs://neo-datenbank.appspot.com/elemente/bilder/\(element.name).jpg") else {
            return nil
        }
        return await ladeBildAusDatenbank(photoURL)
    }
    
    static func quizBild(quizName: String) async -> UIImage? {
        if let lokalesBild = leseLokalesBildAus("quizze/\(quizName)") {
            return lokalesBild
        }
        guard let photoURL = URL(string: "gs://neo-datenbank.appspot.com/quizze/\(quizName).jpg") else {
            return nil
        }
        return await ladeBildAusDatenbank(photoURL)
    }
        
    static func lade3dModell(fuer element: String) async -> SCNScene? {
        guard let urlPrefix = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let lokaleURL = urlPrefix.appendingPathComponent("\(element).usdz")
        do {
            if FileManager.default.fileExists(atPath: lokaleURL.path) {
                let scene = try SCNScene(url: lokaleURL)
                scene.background.contents = UIColor(.gray)
                await MainActor.run {
                    scene.rootNode.simdScale.y = 1.4
                    scene.rootNode.simdScale.x = 1.4
                    scene.rootNode.simdScale.z = 1.4
                                    
                    scene.rootNode.childNodes[0].rotation = SCNVector4(0.15, 0, 0, 0.2)
                }
                
                return scene
            } else {
                guard let modellURL = URL(string: "gs://neo-datenbank.appspot.com/elemente/modelle/\(element).usdz") else { return nil }
                
                let referenz = try Storage.storage().reference(for: modellURL)
                let downloadURL = try await referenz.writeAsync(toFile: lokaleURL)
                
                let scene = try SCNScene(url: downloadURL)
                
                scene.background.contents = UIColor(.gray)
                await MainActor.run {
                    scene.rootNode.simdScale.y = 1.4
                    scene.rootNode.simdScale.x = 1.4
                    scene.rootNode.simdScale.z = 1.4
                                    
                    scene.rootNode.childNodes[0].rotation = SCNVector4(0.15, 0, 0, 0.2)
                }
                
                return scene
            }
        } catch {
            print(error)
            return nil
        }
    }
}

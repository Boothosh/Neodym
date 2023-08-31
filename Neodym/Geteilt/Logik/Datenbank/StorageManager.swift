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
        guard let photoURL = Auth.auth().currentUser?.photoURL else {
            return UIImage(named: "Mann")
        }
        return await ladeBild(photoURL, maxGroesse: 1000000)
    }
    
    static func ladeBildFuer(element: Element) async -> UIImage? {
        guard let photoURL = URL(string: "gs://neo-datenbank.appspot.com/elemente/bilder/\(element.name).jpg") else {
            return nil
        }
        return await ladeBild(photoURL, maxGroesse: 1000000)
    }
    
    private static func ladeBild(_ pfad: URL, maxGroesse: Int64) async -> UIImage? {
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

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
        
    // MARK: Bild aus der Datenbank
    private static func ladeBildAusDatenbank(_ teilPfad: String = "", url direktURL: URL? = nil) async -> UIImage? {
        let maxGroesse: Int64 = 10000000 // Maximale Dateigröße ist 10MB
        let url = direktURL ?? URL(string: "gs://neo-datenbank.appspot.com/\(teilPfad).jpg")
        guard let url else { return nil }
        do {
            let referenz = try Storage.storage().reference(for: url)
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
        print("Versuche Bild bei \(lokaleURL) auszulesen.")
        if FileManager.default.fileExists(atPath: lokaleURL.path()) {
            print("Erfolg")
            return UIImage(contentsOfFile: lokaleURL.path())
        } else {
            print("Fehlgeschlagen")
            return nil
        }
    }
    
    private static func schreibeLokalesBild(_ data: Data, andDieStelle teilPfad: String, dateiName: String) {
        guard let urlPrefix = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let lokaleFileURL = urlPrefix.appendingPathComponent("\(teilPfad)\(dateiName).jpg")
        let lokaleDirURL = urlPrefix.appendingPathComponent(teilPfad)
        print("Schreibe Bild an die Stelle \(lokaleFileURL)")
        do {
            try FileManager.default.createDirectory(at: lokaleDirURL, withIntermediateDirectories: true)
        } catch {
            print(error)
        }
        FileManager.default.createFile(atPath: lokaleFileURL.path(), contents: data)
    }
    
    static func speichereProfilbild(_ bild: UIImage) async -> String? {
        guard let benutzer = Auth.auth().currentUser else { return "Benutzer ist nicht korrekt angemeldet." }
        let referenz = Storage.storage().reference().child("profilbilder/\(benutzer.uid).jpg")
        guard let komprimiertesBild = resizeImage(image: bild, targetSize: CGSize(width: 512, height: 512)), let data = komprimiertesBild.jpegData(compressionQuality: 1) else {
            return "Bild konnte nicht komprimiert werden."
        }
        do {
            let _ = try await referenz.putDataAsync(data)
            let changeRequest = benutzer.createProfileChangeRequest()
            changeRequest.photoURL = URL(string: "gs://neo-datenbank.appspot.com/profilbilder/\(benutzer.uid).jpg")
            try await changeRequest.commitChanges()
        } catch {
            print(error)
            return error.localizedDescription
        }
        return nil
    }
    
    static private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    /// Gibt das Profilbild zurück
    /// Im Falle dass noch kein Bild konfiguriert wurde, ein Standart-Bild zurück
    static func ladeProfilbild() async -> UIImage {
        guard let photoURL = Auth.auth().currentUser?.photoURL, let bild = await ladeBildAusDatenbank(url: photoURL) else {
            return UIImage(named: "Mann")!
        }
        return bild
    }
    
    static func ladeBildFuer(element: Element) async -> UIImage? {
        return await ladeBildAusDatenbank("elemente/bilder/\(element.name)")
    }
    
    static func quizBild(quizName: String, bildID: String) async -> UIImage? {
        if let lokalesBild = leseLokalesBildAus("quizze/\(quizName)/\(bildID)") {
            return lokalesBild
        }
        if let pfad = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("quizze/\(quizName)").path() {
            do {
                // Lösche alle alten Bilder
                try FileManager().removeItem(atPath: pfad)
            } catch {
                print(error)
            }
        }
        if let bild = await ladeBildAusDatenbank("quizze/\(quizName)"), let data = bild.jpegData(compressionQuality: 1) {
            schreibeLokalesBild(data, andDieStelle: "quizze/\(quizName)/", dateiName: bildID)
            return bild
        } else {
            return nil
        }
    }
    
    /// Gibt das korrespondierende 3D Modell für ein Element zurück, falls dieses heruntergeladen werden kann oder bereits heruntergeladen wurde
    static func lade3dModell(fuer element: String) async -> SCNScene? {
        guard let urlPrefix = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let lokaleURL = urlPrefix.appendingPathComponent("modelle/\(element).usdz")
        do {
            if !FileManager.default.fileExists(atPath: lokaleURL.path) {
                guard let modellURL = URL(string: "gs://neo-datenbank.appspot.com/elemente/modelle/\(element).usdz") else { return nil }
                let referenz = try Storage.storage().reference(for: modellURL)
                _ = try await referenz.writeAsync(toFile: lokaleURL)
            }
            let scene = try SCNScene(url: lokaleURL)
            await MainActor.run {
                scene.background.contents = UIColor(.gray)
                scene.rootNode.simdScale.y = 1.4
                scene.rootNode.simdScale.x = 1.4
                scene.rootNode.simdScale.z = 1.4
                scene.rootNode.childNodes[0].rotation = SCNVector4(0.15, 0, 0, 0.2)
            }
            return scene
        } catch {
            print(error)
            return nil
        }
    }
    
}

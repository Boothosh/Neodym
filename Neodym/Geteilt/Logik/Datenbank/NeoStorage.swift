//
//  NeoStorage.swift
//  Neodym
//
//  Created by Max Eckstein on 15.07.23.
//

import FirebaseStorage
import FirebaseAuth
import SceneKit
import SwiftUI

struct NeoStorage {
    
    static let prefix = "gs://neo-datenbank.appspot.com/"
        
    // MARK: Bild aus der Datenbank
    private static func ladeBildAusDatenbank(_ teilPfad: String, lokal lokalerPfad: String) async throws -> CrossPlatformImage? {
        let maxGroesse: Int64 = 10_000_000 // Maximale Dateigröße ist 10MB
        guard let storageURL = URL(string: prefix + teilPfad) else { throw Fehler.zielURLNichtErstellbar }
        guard let lokalerPraefix = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else { throw Fehler.lokaleURLNichtErstellbar }
        let referenz = try Storage.storage().reference(for: storageURL)
        return await withCheckedContinuation { continuation in
            referenz.getData(maxSize: maxGroesse) { data, error in
                if let error = error {
                    continuation.resume(returning: nil)
                    print(error)
                } else {
                    guard let data = data else { continuation.resume(returning: nil); return }
                    referenz.write(toFile: lokalerPraefix.appending(path: lokalerPfad))
                    continuation.resume(returning: CrossPlatformImage(data: data))
                    //continuation.resume(returning: UIImage(data: data))
                }
            }
        }
    }
        
    private static func ladeBildLokal(_ teilPfad: String) throws -> CrossPlatformImage? {
        guard let lokalerPraefix = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else { throw Fehler.lokaleURLNichtErstellbar }
        let lokaleURL = lokalerPraefix.appending(path: teilPfad).path()
        if FileManager.default.fileExists(atPath: lokaleURL) {
            return CrossPlatformImage(contentsOfFile: lokaleURL)
        } else {
            return nil
        }
    }
    
    private static func schreibeDatenLokal(_ data: Data, andDieStelle teilPfad: String, dateiName: String) {
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
    
    static func quizBild(quizName: String, bildID: String) async throws -> CrossPlatformImage? {
        if let lokalesBild = try ladeBildLokal("quizze/\(quizName)/\(bildID).jpg") {
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
        return try await ladeBildAusDatenbank("quizze/\(quizName)", lokal: "quizze/\(quizName)/\(bildID).jpg")
    }
    
    /// Gibt das korrespondierende 3D Modell für ein Element zurück, falls dieses heruntergeladen werden kann oder bereits heruntergeladen wurde
    static func lade3dModell(fuer element: String) async throws -> SCNScene {
        guard let urlPrefix = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else { throw Fehler.lokaleURLNichtErstellbar }
        let lokaleURL = urlPrefix.appendingPathComponent("modelle/\(element.ohneUmlaute).usdz")
        if !FileManager.default.fileExists(atPath: lokaleURL.path) {
            guard let modellURL = URL(string: prefix + "elemente/modelle/\(element.ohneUmlaute).usdz") else { throw Fehler.zielURLNichtErstellbar }
            let referenz = try Storage.storage().reference(for: modellURL)
            _ = try await referenz.writeAsync(toFile: lokaleURL)
        }
        let scene = try SCNScene(url: lokaleURL)
        await MainActor.run {
            scene.background.contents = Color.gray
            scene.rootNode.simdScale.y = 1.4
            scene.rootNode.simdScale.x = 1.4
            scene.rootNode.simdScale.z = 1.4
            scene.rootNode.childNodes[0].rotation = SCNVector4(0.15, 0, 0, 0.2)
        }
        return scene
    }
    
    enum Fehler: Error {
        case bildKompressionFehlgeschlagen
        case lokaleURLNichtErstellbar
        case zielURLNichtErstellbar
    }
    
}

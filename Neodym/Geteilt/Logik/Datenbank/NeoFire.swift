//
//  NeoFire.swift
//  Neodym
//
//  Created by Max Eckstein on 16.07.23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseFunctions
import FirebaseAuth

struct NeoFire {
    
    static func ladeElementDetails(fuer element: Element) async -> ([EArtikelSektion], [String]?, [String]?) {
        do {
            let dokument = try await Firestore.firestore().document("/elemente/\(element.name)").getDocument()
            let bildQuellen = dokument.data()?["bildQuellen"] as? [String]
            let textQuellen = dokument.data()?["textQuellen"] as? [String]
            let sammlung = try await Firestore.firestore().collection("/elemente/\(element.name)/inhalt").getDocuments()
            let sektionen: [EArtikelSektion] = sammlung.documents.compactMap {
                return try? $0.data(as: EArtikelSektion.self)
            }
            return (sektionen, textQuellen, bildQuellen)
        } catch {
            print(error)
            return ([], nil, nil)
        }
    }
    
    static func ladeQuizSeiten(fuer quiz: String) async throws -> [QuizSeite]? {
        let sammlung = try await Firestore.firestore().collection("/quizze/\(quiz)/inhalt").getDocuments()
        var quizseiten: [QuizSeite] = []
        for snapchot in sammlung.documents {
            guard let frage = snapchot.data()["frage"] as? String,
            let richt_antworten = snapchot.data()["richt_antw"] as? [String],
                  let moeg_antworten = snapchot.data()["moeg_antw"] as? [String] else {
                continue
            }
            quizseiten.append(QuizSeite(frage: frage, anwortMoeglichkeiten: moeg_antworten, richtigeAnworten: richt_antworten))
        }
        return quizseiten.isEmpty ? nil : quizseiten
    }
    
    static func kaufeLizenzen(_ anzahl: Int) async throws {
        let _ = try await Functions.functions().httpsCallable("kaufeLizenzen").call(["anzahl": anzahl])
    }
    
    static func kaufeTestLizenzen() async throws {
        let _ = try await Functions.functions().httpsCallable("kaufeTestLizenzen").call()
    }
    
    static func ladeLizenzen() async throws -> [Lizenz] {
        guard let uid = Auth.auth().currentUser?.uid else { throw Fehler.nichtAngemeldet }
        let lizenzenRaw = try await Firestore.firestore().collection("/lizenzen").whereField("besitzer", isEqualTo: uid).getDocuments()
        var lizenzen = [Lizenz]()
        for i in lizenzenRaw.documents {
            let id = i.documentID
            let aktiv = i.data()["aktiv"] as? Bool
            let benutzerID = i.data()["benutzer"] as? String
            let endDatum = i.data()["endDatum"] as? Date
            lizenzen.append(Lizenz(schluessel: i.documentID, aktiv: aktiv == true, benutzerID: benutzerID, ablaufdatum: endDatum))
        }
        return lizenzen
    }
    
    enum Fehler: LocalizedError {
        case nichtAngemeldet
    }
    
}

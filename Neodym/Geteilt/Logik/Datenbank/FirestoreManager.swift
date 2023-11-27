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
    
    static func ladeQuizSeiten(fuer quiz: String) async -> [QuizSeite] {
        do {
            let sammlung = try await Firestore.firestore().collection("/quizze/q/\(quiz)").getDocuments()
            var quizseiten: [QuizSeite] = []
            for snapchot in sammlung.documents {
                guard let frage = snapchot.data()["frage"] as? String,
                let richt_antworten = snapchot.data()["richt_antw"] as? [String],
                      let moeg_antworten = snapchot.data()["moeg_antw"] as? [String] else {
                    continue
                }
                quizseiten.append(QuizSeite(frage: frage, anwortMoeglichkeiten: moeg_antworten, richtigeAnworten: richt_antworten))
            }
            return quizseiten
        } catch {
            print(error)
            return []
        }
    }
    
}

//
//  Quiz.swift
//  Neodym
//
//  Created by Max Eckstein on 04.11.23.
//

import Foundation

struct Quiz: Identifiable, Equatable {
    
    static func == (lhs: Quiz, rhs: Quiz) -> Bool {
        lhs.id == rhs.id && lhs.fortschritt == rhs.fortschritt
    }
    
    let id = UUID()
    let titel: String
    var fortschritt: Int // In Prozent
    let schwierigkeit: Schwierigkeit
    let bildName: String
    
    let inhalt: [QuizSeite]
    
    init(titel: String, schwierigkeit: Schwierigkeit, bildName: String, inhalt: [QuizSeite]) {
        self.titel = titel
        self.fortschritt = UserDefaults.standard.integer(forKey: titel)
        self.schwierigkeit = schwierigkeit
        self.bildName = bildName
        self.inhalt = inhalt
    }
}

enum Schwierigkeit: String {
    case einfach = "Einfach"
    case mittel = "Mittel"
    case schwierig = "Schwierig"
}

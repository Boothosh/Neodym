//
//  Quiz.swift
//  Neodym
//
//  Created by Max Eckstein on 04.11.23.
//

import Foundation

struct Quiz: Identifiable {
    
    let id = UUID()
    let titel: String
    var fortschritt: Int // In Prozent
    let schwierigkeit: Schwierigkeit
    let bildName: String
    
    let inhalt: [QuizSeite]
}

enum Schwierigkeit: String {
    case einfach = "Einfach"
    case mittel = "Mittel"
    case schwierig = "Schwierig"
}

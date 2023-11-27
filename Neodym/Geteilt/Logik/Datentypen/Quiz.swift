//
//  Quiz.swift
//  Neodym
//
//  Created by Max Eckstein on 04.11.23.
//

import SwiftUI

struct Quiz: Identifiable, Equatable, Codable {
    
    static func == (lhs: Quiz, rhs: Quiz) -> Bool {
        lhs.id == rhs.id && lhs.fortschritt == rhs.fortschritt
    }
    
    let id = UUID()
    let titel: String
    var fortschritt: Int // In Prozent
    let schwierigkeit: Schwierigkeit
        
    var inhalt: [QuizSeite] = []
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.titel = try container.decode(String.self, forKey: .titel)
        self.fortschritt = UserDefaults.standard.integer(forKey: titel)
        self.schwierigkeit = Schwierigkeit(rawValue: try container.decode(String.self, forKey: .schwierigkeit)) ?? .einfach
    }
    
    enum CodingKeys: String, CodingKey {
        case titel = "titel"
        case schwierigkeit = "schwierigkeit"
    }
}

enum Schwierigkeit: String, Codable {
    case einfach = "einfach"
    case mittel = "mittel"
    case schwierig = "schwierig"
}

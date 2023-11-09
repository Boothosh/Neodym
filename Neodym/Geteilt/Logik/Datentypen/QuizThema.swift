//
//  QuizThema.swift
//  Neodym
//
//  Created by Max Eckstein on 04.11.23.
//

import Foundation

struct QuizThema: Identifiable {
    let id = UUID()
    let titel: String
    var quizes: [Quiz]
}

//
//  QuizSeite.swift
//  Neodym
//
//  Created by Max Eckstein on 04.11.23.
//

import Foundation

struct QuizSeite: Codable, Equatable {
    let frage: String
    let anwortMoeglichkeiten: [String]
    let richtigeAnworten: [String]
}

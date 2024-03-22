//
//  Lizenz.swift
//  Neodym
//
//  Created by Max Eckstein on 28.02.24.
//

import Foundation

struct Lizenz: Identifiable {
    var id: String {
        schluessel
    }
    let schluessel: String
    let aktiv: Bool
    let benutzerID: String?
    let ablaufdatum: Date?
}

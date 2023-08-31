//
//  EArtikelSektion.swift
//  Neodym
//
//  Created by Max Eckstein on 05.09.23.
//

import Foundation

struct EArtikelSektion: Identifiable {
    
    let id = UUID()
    
    // Inhalt
    let titel: String
    let text: String
    let bildPfad: String?
    
    // Quellen
    let textQuelle: String
    let bildQuelle: String?
}

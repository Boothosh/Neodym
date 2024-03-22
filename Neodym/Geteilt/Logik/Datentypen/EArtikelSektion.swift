//
//  EArtikelSektion.swift
//  Neodym
//
//  Created by Max Eckstein on 05.09.23.
//

import SwiftUI

struct EArtikelSektion: Identifiable, Codable {
    
    let id = UUID()
    
    // Inhalt
    let titel: String
    let text: String
    let bildPfad: String?
    
    func bild() -> UIImage? {
        return nil
    }
}

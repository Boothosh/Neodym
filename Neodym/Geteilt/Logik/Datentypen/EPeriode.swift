//
//  EPeriode.swift
//  Neodym
//
//  Created by Max Eckstein on 06.06.23.
//

import Foundation

struct EPeriode: Identifiable {
    
    let nummer: String
    let elemente: [Element]
    
    // Für das Identifiable Protokoll
    
    var id: String {
        nummer
    }
}

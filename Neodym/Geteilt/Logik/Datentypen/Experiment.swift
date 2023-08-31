//
//  Experiment.swift
//  Neodym
//
//  Created by Max Eckstein on 11.06.23.
//

import Foundation

struct Experiment: Identifiable, Codable {
    
    let id: UUID
    
    let name: String
    let beschreibung: String
    let erscheinungsDatum: Date
    let kategorien: [String]
    let coverBildPfad: String
    
    let einleitung: String
    
    let kapitel: [Kapitel]
    
    let beteiligteElemente: [Element]
    let warnhinweise: [String]
    
    struct Kapitel: Identifiable, Codable {
        
        let id: UUID
        
        let titel: String
        let inhalt: String
        
        let bildPfad: String
        
    }
    
}

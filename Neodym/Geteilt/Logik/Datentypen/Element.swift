//
//  Element.swift
//  Neodym
//
//  Created by Max Eckstein on 05.06.23.
//

import Foundation

struct Element: Hashable, Codable, Equatable, Identifiable, Comparable {
    static func < (lhs: Element, rhs: Element) -> Bool {
        lhs.name < rhs.name
    }
    
    
    // Statische Werte
    let name: String
    let symbol: String
    
    let kernladungszahl: Int
    let atommasse: Float // Einheit: Atomare Masseeinheit (u)
    let elektroNegativität: Float? // Pauli-Skala
    let orbitale: String
    let radius: Int? // In Picometer
    
    // TODO: Eigentlich sollten Schmelz- und Siedepunkt Temperatur-Datentypen sein
    let schmelzpunkt: Float? // Einheit: Kelvin (K)
    let siedepunkt: Float? // Einheit: Kelvin (K)
    
    // Ist variabel, denn beim Molekülzeichner können Valenzelektronen hinzugefügt oder abgezogen werden
    let valenzElektronen: Int
    
    let klassifikation: String
    let entdeckt: Int
    
    // Für die Berechnung von Ionengruppen
    // Ist bei Metallen negativ
    let elektronenBisEdelgas: Int?
    
    // Für das Identifiable Protokoll
    var id: Int {
        kernladungszahl
    }
    
}

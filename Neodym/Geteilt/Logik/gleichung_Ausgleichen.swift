//
//  gleichung_Ausgleichen.swift
//  Neodym
//
//  Created by Max Eckstein on 15.06.23.
//

import Foundation

/// Funktion in der folgenden Formd „H₂ + O₂ ⇋ H₂O“
/// sollte als edukte = [(["H": 2]), (["O": 2])] und produkte = [(["H": 2, "O": 1])] codiert werden.
/// Das erste zurückgegebene Int-Array entspricht den Anzahlen der Edukte, das zweite der Anzahlen der Produkte.
func gleichung_Ausgleichen(edukte edIn: [REinheit], produkte prodIn: [REinheit]) throws -> ([Int], [Int])  {
    
    // Entscheidung gegen „inout“, da die Funktion möglicherweise im Hintergrund läuft,
    // und es sonst zu einem Data-Race kommen könnte.
    var edukte = edIn
    var produkte = prodIn
    
    for einheiten in (edukte + produkte){
        // Lineare Gleichungssysteme aufstellen
    }
    
    return (edukte.map({ i in i.anzahl }), produkte.map({ i in i.anzahl }))
}

/// Einheit, mit dem Präfix R, da optimiert fürs Rechnen
struct REinheit: Hashable {
    var anzahl: Int = 1         // Standartwert
    let inhalt: [String: Int]   // Symbol und Anzahl des zugehörigen Elementes pro Einheit
                                // Bsp: H₂ => ["H": 2]
}

//
//  CanvasBindung.swift
//  Neodym
//
//  Created by Max Eckstein on 08.06.23.
//

import Foundation

struct CanvasBindung: Identifiable, Equatable {
    
    // ID für Identifikation
    var id: UUID = UUID()
    
    // IDs der zu verbindenden Canvas Objekte
    var erstesCanvasObjekt: UUID
    var ersteElPositionen: [Int]
    var zweitesCanvasObjekt: UUID
    var zweiteElPositionen: [Int]
    
    // Art der Bindung
    var wertigkeit: Int
    
    // Gibt Bool zurück, ob das Erhöhen erfolgreich war
    mutating func erhoeheWertigkeit(_ positionen: [(UUID, Int)]) throws {
        guard wertigkeit < 3 else { throw NutzerFehler.schonDreiBindungen }
        for i in positionen {
            if i.0 == erstesCanvasObjekt {
                ersteElPositionen.append(i.1)
            } else {
                zweiteElPositionen.append(i.1)
            }
        }
        wertigkeit += 1
    }
}

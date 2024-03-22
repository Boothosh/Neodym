//
//  NutzerFehler.swift
//  Neodym
//
//  Created by Max Eckstein on 01.10.23.
//

import Foundation

enum NutzerFehler: Error {
    
    case unverifizierterKauf
    case schonDreiBindungen
    
    func titelUndBeschreibung() -> (String, String) {
        switch self {
            case .unverifizierterKauf:
                return ("Fehler bei der Kauf-Verifizierung", "Die auf diesem Gerät in dieser App getätigten Käufe wurde nicht vom App Store signiert.")
            case .schonDreiBindungen:
                return ("Bindung kann nicht hinzugefügt werden", "Es wurde versucht die Wertigkeit eine Bindung zu erhöhen, obwohl diese schon 3-bindig war.")
        }
    }
}

protocol NZFehler {
    var titel: String { get }
    var text: String { get }
}

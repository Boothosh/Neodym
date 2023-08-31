//
//  IUPACNomenklatur.swift
//  Neodym
//
//  Created by Max Eckstein on 03.08.23.
//

struct IUPACNomenklatur {
    
    /// Gibt, falls es einen Namen findet, den Namen des Moleküls zurück
    /// Momentan wird nur die Benennung von Organischen Molekülen unterstützt
    static func bennene(teilchen: [CanvasObjekt], bindungen: [CanvasBindung]) -> String? {
        // Sicherstellen, dass Teilchen und Bindungen übergeben wurden
        guard teilchen.count != 0 && bindungen.count != 0 else { return nil }
        // Sicherstellen, dass alle Objekte eine Verbindung miteinander haben
        
        var molekuelname = ""
        // Wichtigste charakterisierende Gruppe finden
        
        // Format der Names: "(name)*n-HauptKette-PositionFunktionelleGruppe-AnzahlFunktionielleGruppe-SuffixfunktionelleGruppe"
        
        return molekuelname
    }
    
    /// Veröffentlicht unter https://github.com/Boothosh/griechische_Zahlenwoerter
    static private func griechischesZahlenWort(_ eingabeZahl: Int) -> String {
        // Die eingegebene Zahl wird in ihre Ziffern zerlegt
        let zahlen = eingabeZahl.description.compactMap { Int(String($0)) }
        // Falls die Zahl nicht im angegebenen Bereich liegt, wird kein Wort generiert.
        guard zahlen.count < 5 && eingabeZahl != 0 else { return "Es konnte kein Zahlenwort generiert werden" }
        // Ausnahmen
        guard eingabeZahl != 1 else { return "mono" }
        guard eingabeZahl != 11 else { return "undeca" }
        guard eingabeZahl != 20 else { return "icosa" }
        guard eingabeZahl != 21 else { return "henicosa" }
        // Zuordnung von Wörtern und Ziffern, abhängig von deren Stellenwert
        let zahlenWoerter = [
            ["hen", "do", "tri", "tetra", "penta", "hexa", "hepta", "octa", "nona"],
            ["deca", "cosa", "triaconta", "tetraconta", "pentaconta", "hexaconta", "heptaconta", "octaconta", "nonaconta"],
            ["hecta", "dicta", "tricta", "tetracta", "pentacta", "hexacta", "heptacta", "octacta", "nonacta"],
            ["kilia", "dilia", "trilia", "tetralia", "pentalia", "hexalia", "heptalia", "octalia", "nonalia"]
        ]
        // Zunächst ist das Zahlwort ein leerer String
        var zahlenWort = ""
        // Das Zahlenarray wird umgedreht, damit zuerst die Ziffern mit geringerem Stellenwert kommen, da diese im Wort später vorne stehen.
        // Außerdem wird jeder Ziffer ihr Index mithilfe der enumerated-Funktion mitgegeben.
        for ziffer in zahlen.reversed().enumerated() {
            // Wenn die Ziffer 0 ist, wird nichts hinzugefügt
            guard ziffer.element != 0 else { continue }
            zahlenWort.append(zahlenWoerter[ziffer.offset][ziffer.element - 1])
        }
        return zahlenWort
    }
    
    enum CharakterisierendeGruppe: String {
        case deprotonierteSaeuregruppe = "carboxylat"
        case saeuregruppe = "säure"
    }
    
}


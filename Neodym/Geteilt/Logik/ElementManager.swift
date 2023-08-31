//
//  ElementManager.swift
//  Neodym
//
//  Created by Max Eckstein on 06.06.23.
//

import Foundation

struct ElementManager {
    
    // Normale Elemente
    var perioden: [EPeriode] = []
    
    // Spezielle Gruppen
    var actinoide: [Element] = []
    var lanthanoide: [Element] = []
    
    // Alle Elemente
    var alleElemente: [Element] = []
    
    mutating func ladeDatei() async {
        guard perioden.isEmpty else { return }
        if let url = Bundle.main.url(forResource: "elemente", withExtension: "json") {
            do {
                let daten = try Data(contentsOf: url)
                let entschluessler = JSONDecoder()
                let jsonDaten = try entschluessler.decode([String: [Element]].self, from: daten)
                for i in jsonDaten.keys {
                    if i == "Lanthanoide" {
                        self.lanthanoide = jsonDaten[i]!
                    } else if i == "Actinoide" {
                        self.actinoide = jsonDaten[i]!
                    } else {
                        self.perioden.append(EPeriode(nummer: i, elemente: jsonDaten[i]!))
                    }
                    for ii in jsonDaten[i]! {
                        if ii.name != "Platzhalter" && ii.name != "Actinium-Button" && ii.name != "Lanthan-Button" {
                            alleElemente.append(ii)
                        }
                    }
                }
                perioden.sort { x, i in
                    x.nummer < i.nummer
                }
                alleElemente.sort { $0.kernladungszahl < $1.kernladungszahl}
            } catch {
                print("error:\(error)")
            }
        }
    }
    
}

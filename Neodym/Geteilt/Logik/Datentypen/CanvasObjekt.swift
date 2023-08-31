//
//  CanvasObjekt.swift
//  Neodym
//
//  Created by Max Eckstein on 08.06.23.
//

import SwiftUI

struct CanvasObjekt: Identifiable, Equatable {
    
    // ID für Identifikation
    var id: UUID = UUID()
    
    // Position
    var ort = CGPoint.zero
    var drehung: Angle = Angle(degrees: 0)
    
    // Inhalt
    let element: Element
    var ladung: Int = 0
    
    // Wenn vom ersten Valenzelektron eine Bindung ausgeht, so wäre in dem Array [1]
    // Bei maximal vielen Bindungen sind in dem Array [1, 2, 3, 4]
    var bestehendeBindungen: [Int] = []
    
    // Valenzelektronen
    var valenzelektronen: [Int] = []
    
    init(_ element: Element) {
        self.element = element
        // Fülle das Valenzelektronen-Array
        for i in 1...element.valenzElektronen {
            valenzelektronen.append(i)
        }
    }
    
    func koennteBindungEingehen(_ elektronenNummer: Int) -> Bool {
        // Das Elektron muss vorhanden sein und noch in keiner Bindung
        guard valenzelektronen.contains(elektronenNummer) && !bestehendeBindungen.contains(elektronenNummer) else { return false }
        if element.kernladungszahl - ladung < 3 {
            // Verhält sich wie oder ist  Helium / Wasserstoff
            // Es muss sich um das erste Elektron handeln und es darf noch keine 2 Valenzelektronen haben
            return elektronenNummer == 1 && !valenzelektronen.contains(2)
        } else {
            // Es sollte sich nicht um ein freies Elektronenpaar handeln
            return !bestehendeBindungen.contains(elektronenNummer + 4)
        }
    }
    
    mutating func neueBindung(_ bindungsElektron: Int) {
        bestehendeBindungen.append(bindungsElektron)
    }
    
    // Gibt zurück, ob Operation erfolgreich war
    mutating func ladeNegativ() -> Bool {
        if element.kernladungszahl - ladung < 3 {
            if valenzelektronen.count == 2 {
                valenzelektronen = [1]
            } else if bestehendeBindungen.count == 0 {
                var schonHinzugefuegt = false
                for i in 1...4 {
                    if !valenzelektronen.contains(i) {
                        valenzelektronen.append(i)
                        schonHinzugefuegt = true
                        break
                    }
                }
                if !schonHinzugefuegt {
                    for i in 1...4 {
                        if !bestehendeBindungen.contains(i) && !valenzelektronen.contains(i + 4) {
                            valenzelektronen.append(i + 4)
                            break
                        }
                    }
                }
            } else {
                return false
            }
        } else if valenzelektronen.count < 4 || bestehendeBindungen.count != 8 - valenzelektronen.count {
            var schonHinzugefuegt = false
            for i in 1...4 {
                if !valenzelektronen.contains(i) {
                    valenzelektronen.append(i)
                    schonHinzugefuegt = true
                    break
                }
            }
            if !schonHinzugefuegt {
                for i in 1...4 {
                    if !bestehendeBindungen.contains(i) && !valenzelektronen.contains(i + 4) {
                        valenzelektronen.append(i + 4)
                        break
                    }
                }
            }
        } else if valenzelektronen.count == 8 {
            valenzelektronen = [1]
        } else {
            return false
        }
        ladung -= 1
        return true
    }
    
    // Gibt zurück, ob Operation erfolgreich war
    mutating func ladePositiv() -> Bool {
        if valenzelektronen.count == 1 && bestehendeBindungen.count == 0 {
            if element.kernladungszahl - ladung == 0 {
                return false
            } else if element.kernladungszahl - ladung == 1 {
                valenzelektronen = []
            } else if element.kernladungszahl - ladung == 3 {
                valenzelektronen = [1, 2]
            } else {
                valenzelektronen = [1, 2, 3, 4, 5, 6, 7, 8]
            }
        } else if valenzelektronen.count - bestehendeBindungen.count > 0 {
            var schonabgezogen = false
            for i in (5...8).reversed() {
                if valenzelektronen.contains(i) {
                    valenzelektronen.removeLast()
                    schonabgezogen = true
                    break
                }
            }
            if !schonabgezogen {
                for i in (1...4).reversed() {
                    if valenzelektronen.contains(i) && !bestehendeBindungen.contains(i) {
                        guard let index = valenzelektronen.firstIndex(of: i) else { return false }
                        valenzelektronen.remove(at: index)
                        break
                    }
                }
            }
        } else {
            return false
        }
        ladung += 1
        return true
    }
    
}

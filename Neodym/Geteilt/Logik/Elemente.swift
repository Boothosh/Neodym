//
//  ElementManager.swift
//  Neodym
//
//  Created by Max Eckstein on 06.06.23.
//

import Foundation
import CoreSpotlight
import SwiftUI

@MainActor
@Observable class Elemente {
    
    nonisolated init() {}
    
    // Normale Elemente
    var perioden: [EPeriode] = []
    
    // Spezielle Gruppen
    var actinoide: [Element] = []
    var lanthanoide: [Element] = []
    
    // Alle Elemente
    var alleElemente: [Element] = []
    
    var spotlightEintraegeVorhanden = UserDefaults.standard.bool(forKey: "spotlight")
    var willkeinSpotlight = UserDefaults.standard.bool(forKey: "willkeinSpotlight")
    
    func delayedInit() async {
        await ladeDatei()
        if !spotlightEintraegeVorhanden && !willkeinSpotlight {
            await indexeFuerSpotlight()
        }
        print("[Elemente]: delayedInit() abgeschlossen")
    }
    
    func ladeDatei() async {
        guard perioden.isEmpty else { return }
        if let url = Bundle.main.url(forResource: "elemente", withExtension: "json") {
            do {
                let daten = try Data(contentsOf: url)
                let jsonDaten = try JSONDecoder().decode([String: [Element]].self, from: daten)
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
        
        // Alle Elemente zur Spotlight-Suche hinzufügen, falls noch keine hinzugefügt wurden
        if !spotlightEintraegeVorhanden {
            // Sichergehen, dass tatsächlich keine Objekte vorhanden sind
            await loescheSpotlightEintraege()
            await indexeFuerSpotlight()
        }
    }
    
    func indexeFuerSpotlight() async {
        var searchableItems = [CSSearchableItem]()
        alleElemente.forEach {
            
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.displayName = $0.name
            attributeSet.contentDescription = "\($0.name) (\($0.symbol)) ist ein \($0.klassifikation) und hat die Ordnungszahl \($0.kernladungszahl). Erfahre mehr in der Neodym App ↗️"
            attributeSet.keywords = [$0.klassifikation, $0.name, $0.symbol]
            attributeSet.thumbnailData = UIImage(named: $0.symbol)?.pngData()
            // Create searchable item
            let searchableItem = CSSearchableItem(uniqueIdentifier: $0.name, domainIdentifier: "de.max.eckstein.Neodym", attributeSet: attributeSet)
            searchableItem.expirationDate = Date.distantFuture
            searchableItems.append(searchableItem)
        }
        // Submit for indexing
        do {
            try await CSSearchableIndex.default().indexSearchableItems(searchableItems)
            spotlightEintraegeVorhanden = true
            willkeinSpotlight = false
            UserDefaults.standard.set(true, forKey: "spotlight")
            UserDefaults.standard.set(false, forKey: "willkeinSpotlight")
        } catch {
            print(error)
        }
    }
    
    func loescheSpotlightEintraege() async {
        do {
            try await CSSearchableIndex.default().deleteAllSearchableItems()
            spotlightEintraegeVorhanden = false
            UserDefaults.standard.set(false, forKey: "willkeinSpotlight")
        } catch {
            print(error)
        }
    }
    
}

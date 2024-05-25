//
//  IonengruppenBilden.swift
//  Neodym
//
//  Created by Max Eckstein on 13.07.23.
//

import SwiftUI

struct IonengruppenBilden: View {
    
    @Environment(Elemente.self) private var elemente
    @State private var metall: Element?
    @State private var nichtMetall: Element?
    
    var anzahlen: (Int, Int)? {
        
        guard let metall = metall, let nichtMetall = nichtMetall, let metallElektronenBisEdelgas = metall.elektronenBisEdelgas, let nichtMetallElektronenBisEdelgas = nichtMetall.elektronenBisEdelgas else { return nil }
        
        // Finde den größten gemeinsamen Teiler
        var x = 0
        var y: Int = max(abs(metallElektronenBisEdelgas), nichtMetallElektronenBisEdelgas)
        var z: Int = min(abs(metallElektronenBisEdelgas), nichtMetallElektronenBisEdelgas)

        while z != 0 {
           x = y
           y = z
           z = x % y
        }
        
        // Leite das kleinste gemeinsame Vielfache her
        let kgV = abs(metallElektronenBisEdelgas * nichtMetallElektronenBisEdelgas) / y
        
        // Gebe erst die benötigte Anzahl des Metalls, dann die benötigte Anzahl des Nichtmetalls zurück
        return (kgV/abs(metallElektronenBisEdelgas), kgV/nichtMetallElektronenBisEdelgas)
    }
        
    var body: some View {
        Form {
            Section("Ergebnis") {
                if let metall, let nichtMetall, let anzahlen {
                    HStack(alignment: .center, spacing: 2){
                        Text(metall.symbol)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        VStack {
                            if let el = metall.elektronenBisEdelgas {
                                Text((-el).formatiertAlsLadung)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Spacer()
                            }
                        }
                        VStack {
                            Spacer()
                            Text(anzahlen.0.description)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        Text(nichtMetall.symbol)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        VStack {
                            if let el = nichtMetall.elektronenBisEdelgas {
                                Text((-el).formatiertAlsLadung)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                Spacer()
                            }
                        }
                        VStack {
                            Spacer()
                            Text(anzahlen.1.description)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }.frame(height: 40)
                } else {
                    Text("Hier wird dir das Ergebnis angezeigt, wenn du ein Metall und ein Nichtmetall ausgewählt hast :)")
                        .font(.caption)
                }
            }
            Section("Eingabe") {
                Text("Wähle ein Metall und ein Nichtmetall aus, welche deine Ionengruppe bilden sollen. Der Rechner gleicht die Gruppe anschließend stöchiometrisch für dich aus.")
                    .font(.caption)
                Picker("Metall", selection: $metall) {
                    Text("Auswählen").tag(nil as Element?)
                    ForEach(elemente.alleElemente.filter({$0.elektronenBisEdelgas ?? 0 < 0}).sorted()) { element in
                        Text(element.name)
                            .tag(element as Element?)
                    }
                }
                Picker("Nichtmetall", selection: $nichtMetall) {
                    Text("Auswählen").tag(nil as Element?)
                    ForEach(elemente.alleElemente.filter({$0.elektronenBisEdelgas ?? 0 > 0}).sorted()) { element in
                        Text(element.name)
                            .tag(element as Element?)
                    }
                }
            }
            Section("Selbst nachrechnen") {
                VStack(alignment: .leading, spacing: 9){
                    Text("Schritt 1:")
                        .font(.caption)
                        .underline()
                    Text("Prüfe, dass eines deiner zwei Elemente als Metall und das andere als Nichtmetall reagiert.")
                }
                VStack(alignment: .leading, spacing: 9){
                    Text("Schritt 2:")
                        .font(.caption)
                        .underline()
                    Text("Notiere dir bei deinem Metall, wieviele Elektronen es abgeben muss, um die Edelgaskonfiguration (8 Außenelektronen) zu erreichen.\nNotiere dir auch, wieviele Elektronen dein Nichtmetall aufnehmen muss, um die Edelgaskonfiguration zu erreichen.")
                }
                VStack(alignment: .leading, spacing: 9){
                    Text("Schritt 3:")
                        .font(.caption)
                        .underline()
                    Text("Berechne nun das kgV (kleinste gemeinsame Vielfache) der von dir aufgeschrieben Zahlen.")
                }
                VStack(alignment: .leading, spacing: 9){
                    Text("Schritt 4:")
                        .font(.caption)
                        .underline()
                    Text("Um die Anzahl der benötigten Metall-Atome zu erhalten, teile das kgV durch die beim Metall notierte Zahl. Gehe analog beim Nichtmetall vor.\nFertig!")
                }
                
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Ionengruppen bilden")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

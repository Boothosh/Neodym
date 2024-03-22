//
//  MolekuelmasseRechner.swift
//  Neodym
//
//  Created by Max Eckstein on 12.07.23.
//

import SwiftUI
import Charts

struct MolekuelmasseRechner: View {
    
    // Zugriff auf die Elemente
    @Environment(Elemente.self) private var elemente
    
    // Status des Rechners
    @State private var elementeMitAnzahl: [Element: Int] = [:]
    
    var elementeAlsArray: [Element] { Array(elementeMitAnzahl.keys) }
    var molekuelmasse: Float {
        elementeAlsArray.reduce(0) {
            $0 + $1.atommasse * Float(elementeMitAnzahl[$1]!)
        }
    }
    
    // Summenformel-Eingabe
    @State private var summenformel = ""
    
    @State private var zeigeHinzufuegenPopUp = false
    
    var body: some View {
        List {
            Section("Ergebnis"){
                Text("\(molekuelmasse, specifier: "%.0f") g/mol")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .animation(.easeInOut(duration: 0.2))
                if elementeMitAnzahl.count == 0 {
                    Text("Sind halt aber auch noch keine Atome hinzugefügt worden :)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            Section("Eingabe via Summenformel"){
                TextField("Bspw. C2H5OH", text: $summenformel)
                    .autocorrectionDisabled()
                    .onSubmit {
                        withAnimation{
                            let ergebnis = summenformelEinlesen()
                            if ergebnis.count != 0 {
                                elementeMitAnzahl = ergebnis
                            }
                            summenformel = ""
                        }
                    }
                Button {
                    withAnimation{
                        let ergebnis = summenformelEinlesen()
                        if ergebnis.count != 0 {
                            elementeMitAnzahl = ergebnis
                        }
                        summenformel = ""
                    }
                } label: {
                    Text("Berechnen")
                }.keyboardShortcut(.defaultAction)
                .disabled(summenformel.isEmpty)
            }
            Section("Manuelle Eingabe"){
                if elementeMitAnzahl.count == 0 {
                    Text("Füge Atome hinzu!")
                } else {
                    ForEach(elementeAlsArray) { element in
                        HStack{
                            Text(element.name)
                            Spacer()
                            Button {
                                guard let anzahl = elementeMitAnzahl[element] else { return }
                                if anzahl != 1 {
                                    elementeMitAnzahl[element] = anzahl - 1
                                } else {
                                    elementeMitAnzahl[element] = nil
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            // .buttonStyle(.plain) muss da sein, da sonst in Forms die Aktion von allen Buttons in der selben Row ausgeführt wird.
                            // Danach muss der Button blau eingefärbt werden, da er durch .buttonStyle(.plain) schriftfarben wird.
                            // Siehe mehr unter https://stackoverflow.com/questions/57947581/why-buttons-dont-work-when-embedded-in-a-swiftui-form
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            Text("\(elementeMitAnzahl[element] ?? 0)")
                            Button {
                                guard let anzahl = elementeMitAnzahl[element] else { return }
                                elementeMitAnzahl[element] = anzahl + 1
                            } label: {
                                Image(systemName: "plus.circle")
                            }.buttonStyle(.plain)
                                .foregroundColor(.blue)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet {
                            let geloeschtesElement = elementeAlsArray[i]
                            elementeMitAnzahl.removeValue(forKey: geloeschtesElement)
                        }
                    }
                }
                Button {
                    zeigeHinzufuegenPopUp = true
                } label: {
                    Text("Neues Atom hinzufügen")
                }
            }
            if elementeAlsArray.count != 0 {
                Section("Anteil am Gesamtgewicht"){
                    if elementeAlsArray.count > 1 {
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            gewichtChart
                            ForEach(elementeAlsArray) { element in
                                HStack{
                                    Text(element.name)
                                    Spacer()
                                    Text("\((Float(elementeMitAnzahl[element] ?? 0)*element.atommasse) / molekuelmasse, specifier: "%.2f") %")
                                }
                            }
                        } else {
                            HStack(spacing: 30){
                                gewichtChart
                                List(elementeAlsArray) { element in
                                    HStack{
                                        Text(element.name)
                                        Spacer()
                                        Text("\((Float(elementeMitAnzahl[element] ?? 0)*element.atommasse) / molekuelmasse, specifier: "%.2f") %")
                                    }
                                }.cornerRadius(15)
                            }
                        }
                    } else if elementeAlsArray.count == 1 {
                        Text("100% \(elementeAlsArray[0].name)...")
                    }
                }
            }
            Section("Selbst nachrechnen") {
                VStack(alignment: .leading, spacing: 9){
                    Text("Schritt 1:")
                        .font(.caption)
                        .underline()
                    Text("Schaue nach, welche Atome in deinem Molekül vorkommen und notiere sie zusammen mit ihrer Anzahl.")
                }
                VStack(alignment: .leading, spacing: 9){
                    Text("Schritt 2:")
                        .font(.caption)
                        .underline()
                    Text("Recherchiere die relative Atommasse in u oder g/mol und notiere sie neben die Atome.")
                }
                VStack(alignment: .leading, spacing: 9){
                    Text("Schritt 3:")
                        .font(.caption)
                        .underline()
                    Text("Multipliziere die relative Atommasse der Atome mit der jeweiligen Häufigkeit des Atoms und addiere die Ergebnisse.\nFertig!")
                }
            }
            
        }.navigationTitle("Molekülmasse berechnen")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $zeigeHinzufuegenPopUp) {
                ElementAuswahlListe(hinzufuegen: { element in
                    if let vorherigeAnzahl = elementeMitAnzahl[element] {
                        elementeMitAnzahl[element] = vorherigeAnzahl + 1
                    } else {
                        elementeMitAnzahl[element] = 1
                    }
                }).environment(elemente)
            }
    }
    
    @MainActor private func summenformelEinlesen() -> [Element: Int] {
        var eingeleseneElementeMitZahlen = [Element: Int]()
        let extrahierteBausteine = matches(for: "[A-Z][a-z]{0,1}[0-9]*", in: summenformel)
        for i in extrahierteBausteine {
            guard let symbol = matches(for: "[A-Z][a-z]{0,1}", in: i).first else { continue }
            var anzahlAlsString = matches(for: "[0-9]*", in: i)
            anzahlAlsString.removeAll(where: {$0 == ""})
            var anzahl = 0.0
            var multiplikator = pow(10.0, Double(anzahlAlsString.first?.count ?? 0) - 1.0)
            for i in anzahlAlsString.first ?? "" {
                let aktuelleAnzahl = Double(String(i)) ?? 0
                anzahl += multiplikator * aktuelleAnzahl
                multiplikator /= 10
            }
            if anzahl == 0.0 {
                anzahl = 1.0
            }
            for element in elemente.alleElemente {
                if element.symbol == symbol {
                    if let voherigeAnzahl = eingeleseneElementeMitZahlen[element] {
                        eingeleseneElementeMitZahlen[element] = voherigeAnzahl + Int(anzahl)
                    } else {
                        eingeleseneElementeMitZahlen[element] = Int(anzahl)
                    }
                    break
                }
            }
        }
        return eingeleseneElementeMitZahlen
    }
    
    // Funktion kopiert (leicht modifiziert) von Martin R, verfügbar unter https://stackoverflow.com/questions/27880650/swift-extract-regex-matches
    func matches(for regex: String, in text: String) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.compactMap {
                Range($0.range, in: text).map { String(text[$0]) }
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    var gewichtChart: some View {
        Chart(elementeAlsArray) { element in
            SectorMark(
                angle: .value("Value", Float(elementeMitAnzahl[element] ?? 0)*element.atommasse),
                innerRadius: .ratio(0.618),
                outerRadius: .inset(10),
                angularInset: 1
            )
            .foregroundStyle(by: .value("Element", element.name))
            .cornerRadius(4)
        }
        .frame(width: 300, height: 300)
            .chartBackground { chartProxy in
              GeometryReader { geometry in
                  if let plotFrame = chartProxy.plotFrame {
                      VStack {
                          Text("Schwerstes Atom")
                              .font(.callout)
                              .foregroundStyle(.secondary)
                          Text(elementeAlsArray.sorted(by: {$0.atommasse > $1.atommasse}).first?.name ?? "Fehler")
                              .font(.title2.bold())
                              .foregroundColor(.primary)
                      }
                      .position(x: geometry[plotFrame].midX, y: geometry[plotFrame].midY)
                  }
              }
            }
    }
}

//
//  MolekuelmasseRechner.swift
//  Neodym
//
//  Created by Max Eckstein on 12.07.23.
//

import SwiftUI

struct MolekuelmasseRechner: View {
    
    // Zugriff auf die Elemente
    @Binding var elementManager: ElementManager
    
    // Status des Rechners
    @State private var elementeMitAnzahl: [Element: Int] = [:]
    var elementeAlsArray: [Element] { Array(elementeMitAnzahl.keys) }
    var molekuelmasse: Float {
        elementeAlsArray.reduce(0) {
            $0 + $1.atommasse * Float(elementeMitAnzahl[$1]!)
        }
    }
    @State private var kuchenDiagrammAnteile: [KuchenDiagrammAnteil]?
    
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
                Button {
                    withAnimation{
                        let ergebnis = summenformelEinlesen()
                        if ergebnis.count != 0 {
                            elementeMitAnzahl = ergebnis
                            kuchenDiagrammAnteile = errechneKuchenDiagrammAnteile()
                        }
                        summenformel = ""
                    }
                } label: {
                    Text("Berechnen")
                }
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
                                kuchenDiagrammAnteile = errechneKuchenDiagrammAnteile()
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
                                kuchenDiagrammAnteile = errechneKuchenDiagrammAnteile()
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
                            kuchenDiagrammAnteile = errechneKuchenDiagrammAnteile()
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
                    if elementeAlsArray.count == 1 {
                        Text("Ist halt 100% \(elementeAlsArray[0].name)...")
                    } else if let kuchenDiagrammAnteile {
                        // Kuchendiagramm
                        ZStack {
                            // Inspiriert von "Build Pie Charts in SwiftUI von Nazar Ilamanov". Verfügbar unter https://betterprogramming.pub/build-pie-charts-in-swiftui-822651fbf3f2
                            ForEach(kuchenDiagrammAnteile) { anteil in
                                Path { pfad in
                                    let groesse = 300.0
                                    let zentrum = CGPoint(x: groesse * 0.5, y: groesse * 0.5)
                                    pfad.move(to: zentrum)
                                    pfad.addArc(center: zentrum, radius: groesse * 0.5, startAngle: anteil.startetBei, endAngle: anteil.endedBei, clockwise: false)
                                }.fill(Color(uiColor: anteil.farbe))
                            }
                        }.frame(width: 300, height: 300)
                        ForEach(kuchenDiagrammAnteile) { anteil in
                            HStack{
                                Circle()
                                    .fill(Color(uiColor: anteil.farbe))
                                    .frame(width: 15, height: 15)
                                Text(anteil.name)
                                Spacer()
                                Text("\(anteil.prozentzahl, specifier: "%.2f") %")
                            }
                        }
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
                ElementAuswahlListe(elemente: $elementManager, hinzufuegen: { element in
                    if let vorherigeAnzahl = elementeMitAnzahl[element] {
                        elementeMitAnzahl[element] = vorherigeAnzahl + 1
                    } else {
                        elementeMitAnzahl[element] = 1
                    }
                    kuchenDiagrammAnteile = errechneKuchenDiagrammAnteile()
                })
            }
    }
    
    private struct KuchenDiagrammAnteil: Identifiable, Equatable {
        let id = UUID()
        let startetBei: Angle
        let endedBei: Angle
        let farbe: UIColor
        let symbol: String
        let prozentzahl: Float
        let name: String
    }
    
    private func errechneKuchenDiagrammAnteile() -> [KuchenDiagrammAnteil]? {
        guard elementeAlsArray.count > 1 else { return nil }
        var startWinkel = -90.0
        var neueKuchenDiagrammAnteile = [KuchenDiagrammAnteil]()
        for i in elementeAlsArray {
            let anteilAmGanzen = (Float(elementeMitAnzahl[i]!) * i.atommasse) / molekuelmasse
            let neuerWinkel = Double(anteilAmGanzen * 360.0)
            let endWinkel = startWinkel + neuerWinkel
            if let alterAnteil = kuchenDiagrammAnteile?.first(where: { ii in
                ii.name == i.name
            }) {
                neueKuchenDiagrammAnteile.append(KuchenDiagrammAnteil(startetBei: Angle(degrees: startWinkel), endedBei: Angle(degrees: endWinkel), farbe: alterAnteil.farbe, symbol: i.symbol, prozentzahl: anteilAmGanzen * 100, name: i.name))
            } else {
                neueKuchenDiagrammAnteile.append(KuchenDiagrammAnteil(startetBei: Angle(degrees: startWinkel), endedBei: Angle(degrees: endWinkel), farbe: UIColor.zufaellig, symbol: i.symbol, prozentzahl: anteilAmGanzen * 100, name: i.name))
            }
            startWinkel = endWinkel
        }
        return neueKuchenDiagrammAnteile
    }
    
    private func summenformelEinlesen() -> [Element: Int] {
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
                print(multiplikator)
                anzahl += multiplikator * aktuelleAnzahl
                multiplikator /= 10
            }
            if anzahl == 0.0 {
                anzahl = 1.0
            }
            for element in elementManager.alleElemente {
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
}

// Kopiert und modifiziert
// Orginal von Orkhan Alikhanov, verfügbar unter https://stackoverflow.com/questions/29779128/how-to-make-a-random-color-with-swift
extension UIColor {
    static var zufaellig: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}

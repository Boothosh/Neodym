//
//  ElementeUeberblick.swift
//  Neodym
//
//  Created by Max Eckstein on 10.05.24.
//

import SwiftUI

struct ElementeUeberblick: View {
    
    @Environment(Elemente.self) private var elemente
    
    @Binding var systemIstAusgewaelt: Bool
    @Binding var suchBegriff: String
    @Binding var sucheAktiv: Bool
    @Binding var ausgewaeltesElement: Element?
    @Binding var navigationPath: NavigationPath
    
    // MARK: FÜRS PSE
    
    @State private var zeigeLanthanoide = false
    @State private var zeigeActinoide = false
    
    let gruppenNamen: [Int: String] = [
        1: ("I"),
        2: ("II"),
        13: ("III"),
        14: ("IV"),
        15: ("V"),
        16: ("VI"),
        17: ("VII"),
        18: ("VIII"),
    ]
    
    // MARK: FÜR DIE LISTE
    
    @AppStorage("sortiertNach") private var sortiertNach = "Ordnungszahl"
    @AppStorage("sortiertAufsteigend") private var sortiertAufsteigend = true
    
    // MARK: BODY
    var body: some View {
        hauptview
            .navigationTitle("Elemente")
            .toolbar {
                if !systemIstAusgewaelt {
                    ToolbarItem {
                        Menu("Sortierung", systemImage: "line.3.horizontal.decrease") {
                            Picker(selection: $sortiertNach) {
                                Text("Ordnungszahl")
                                    .tag("Ordnungszahl")
                                Text("Atomradius")
                                    .tag("Atomradius")
                                Text("Entdeckungsjahr")
                                    .tag("Entdeckungsjahr")
                                Text("Name")
                                    .tag("Name")
                            } label: {
                                Text("Sortiert nach")
                            }
                            Divider()
                            Picker(selection: $sortiertAufsteigend) {
                                Text("Aufsteigend")
                                    .tag(true)
                                Text("Absteigend")
                                    .tag(false)
                            } label: {
                                Text("Reihenfolge")
                            }
                        }
                    }
                }
                ToolbarItem {
                    Picker("Ansicht", selection: $systemIstAusgewaelt) {
                        Image("periodensystem")
                            .foregroundStyle(.green, .blue, .cyan)
                            .tag(true)
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.blue, .blue)
                            .tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
    }
    
    @MainActor @ViewBuilder var hauptview: some View {
        if systemIstAusgewaelt {
            pse
                .searchable(text: $suchBegriff, isPresented: $sucheAktiv)
        } else {
            iOSElementListe(navigationPfad: $navigationPath, suchBegriff: $suchBegriff, suche: $sucheAktiv, iPhone: false)
                .environment(elemente)
        }
    }
    
    // MARK: PERIODENSYSTEM
    
    @MainActor var pse: some View {
        GeometryReader { geoD in
            ScrollView {
                let breite: CGFloat = abs((geoD.size.width - 18*1 - 5 - 20)/19)
                VStack(spacing: 1){
                    // Normales Periodensystem
                    HStack(spacing: 1){
                        ForEach(1..<19) { i in
                            VStack(alignment: .center){
                                if let gruppenName = gruppenNamen[i] {
                                    Text(gruppenName)
                                        .font(.system(size: 18, weight: .black))
                                } else {
                                    Text(i.description)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.secondary)
                            .frame(width: breite, height: breite * 1.1)
                        }
                    }.padding(.leading, breite + 1)
                    ForEach(elemente.perioden) { periode in
                        HStack(spacing: 1){
                            Text(periode.nummer)
                                .font(.system(size: 18, weight: .black))
                                .frame(width: breite)
                                .foregroundColor(.secondary)
                            ForEach(periode.elemente) { element in
                                switch element.name {
                                    case "Platzhalter":
                                        Spacer()
                                    case "Lanthan-Button":
                                        Image(systemName: "ellipsis.curlybraces")
                                            .frame(width: breite, height: breite * 1.1)
                                            .background(.gray)
                                            .foregroundColor(.white)
                                            .onTapGesture {
                                                zeigeLanthanoide.toggle()
                                            }
                                    case "Actinium-Button":
                                        Image(systemName: "ellipsis.curlybraces")
                                            .frame(width: breite, height: breite * 1.1)
                                            .background(.gray)
                                            .foregroundColor(.white)
                                            .onTapGesture {
                                                zeigeActinoide.toggle()
                                            }
                                    default:
                                        let ausgegraut = suchBegriff != "" && !element.name.lowercased().contains(suchBegriff.lowercased()) && !element.symbol.lowercased().contains(suchBegriff.lowercased())
                                        ElementKarte(element: element, breite: breite, ausgegraut: ausgegraut)
                                            .onTapGesture {
                                                if !ausgegraut {
                                                    ausgewaeltesElement = element
                                                }
                                            }
                                }
                            }
                        }
                    }
                    if zeigeActinoide || zeigeLanthanoide {
                        Spacer().frame(height: 8)
                    }
                    if zeigeLanthanoide {
                        HStack(spacing: 1){
                            Text("Lanthanoide")
                                .font(.caption)
                                .frame(width: breite*2 + 1)
                            ForEach(elemente.lanthanoide) { element in
                                let ausgegraut = suchBegriff != "" && !element.name.lowercased().contains(suchBegriff.lowercased()) && !element.symbol.lowercased().contains(suchBegriff.lowercased())
                                ElementKarte(element: element, breite: breite, ausgegraut: ausgegraut)
                                    .onTapGesture {
                                        if !ausgegraut {
                                            ausgewaeltesElement = element
                                        }
                                    }
                            }
                        }
                    }
                    if zeigeActinoide {
                        HStack(spacing: 1){
                            Text("Actinoide")
                                .font(.caption)
                                .frame(width: breite*2 + 1)
                            ForEach(elemente.actinoide) { element in
                                let ausgegraut = suchBegriff != "" && !element.name.lowercased().contains(suchBegriff.lowercased()) && !element.symbol.lowercased().contains(suchBegriff.lowercased())
                                ElementKarte(element: element, breite: breite, ausgegraut: ausgegraut)
                                    .onTapGesture {
                                        if !ausgegraut {
                                            ausgewaeltesElement = element
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.leading, 5)
                .padding(.trailing, 20)
                .sheet(item: $ausgewaeltesElement) { element in
                    NavigationStack {
                        ElementDetail(element: element)
                            .toolbar {
                                ToolbarItem {
                                    Button {
                                        ausgewaeltesElement = nil
                                    } label: {
                                        Text("Schließen")
                                    }
                                    .keyboardShortcut(.cancelAction)
                                }
                            }
                    }
                }
            }
        }
            .onChange(of: suchBegriff) {
                zeigeLanthanoide = true
                zeigeActinoide = true
            }
    }
    
    private struct ElementKarte: View, Equatable {
        
        static func == (lhs: ElementKarte, rhs: ElementKarte) -> Bool {
            return lhs.breite == rhs.breite && lhs.ausgegraut == rhs.ausgegraut
        }
        
        let element: Element
        let breite: Double
        let ausgegraut: Bool
        
        var body: some View {
            return Text(element.symbol)
                .font(.system(size: 18, weight: .black))
                .shadow(radius: 5)
                .frame(width: abs(breite - 10), height: abs(breite * 1.1 - 10))
                .overlay(breite > 55 ? Text(element.name)
                    .font(.system(size: 8))
                    .lineLimit(1) : nil, alignment: .bottom)
                .overlay(breite > 55 ? Text(element.kernladungszahl.description)
                    .font(.system(size: 9)) : nil, alignment: .topLeading)
                .overlay(breite > 55 ? Text("\(element.atommasse, specifier: "%.2f")")
                    .font(.system(size: 9)) : nil, alignment: .topTrailing)
                .padding(5)
                .frame(width: breite, height: breite * 1.1)
                .background(ausgegraut ? Color.gray.gradient : Color(element.klassifikation).gradient)
                .foregroundColor(.white.opacity(ausgegraut ? 0.5 : 1))
                .animation(.easeInOut(duration: 0.1), value: ausgegraut)
        }
    }
}

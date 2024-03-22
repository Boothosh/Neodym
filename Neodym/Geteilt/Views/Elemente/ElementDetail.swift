//
//  ElementDetail.swift
//  Neodym
//
//  Created by Max Eckstein on 08.06.23.
//

import SwiftUI
import SceneKit
import QuickLook

struct ElementDetail: View {
    
    let element: Element
        
    @State private var szene: SCNScene?
    @State private var artikelSektionen: [EArtikelSektion] = []
    @State private var textQuellen: [String]? = nil
    @State private var bildQuellen: [String]? = nil
    
    @State private var geladeneInhalte: [String: String] = [:]
    
    @State private var url: URL?
    
    var body: some View {
        Form {
            Section("Steckbrief"){
                HStack(spacing: 12){
                    Text(element.symbol)
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.bold)
                        .shadow(radius: 5)
                        .frame(width: 60, height: 60)
                        .background(Color(element.klassifikation))
                        .cornerRadius(5)
                        .shadow(radius: 5)
                    VStack(alignment: .leading){
                        Text("Relative Atommasse: ")
                        + Text ("\(element.atommasse, specifier: "%.2f") u")
                            .fontWeight(.semibold)
                        Text("Kernladungszahl / Ordnungszahl: ")
                        + Text(element.kernladungszahl.description)
                            .fontWeight(.semibold)
                        if let t = element.elektroNegativität {
                            Text("Elektronegativität: ")
                            + Text("\(t, specifier: "%.2f")")
                                .fontWeight(.semibold)
                            + Text(" (Pauling-Skala)")
                        }
                    }
                    Spacer()
                }
                VStack(alignment: .leading){
                    Text("Gruppe: ")
                    + Text(element.klassifikation)
                        .fontWeight(.semibold)
                    if let t = element.schmelzpunkt {
                        Text("Schmelzpunkt: ")
                        + Text(Temperatur(k: t).formatiert)
                            .fontWeight(.semibold)
                    }
                    if let t = element.siedepunkt {
                        Text("Siedepunkt: ")
                        + Text(Temperatur(k: t).formatiert)
                            .fontWeight(.semibold)
                    }
                    if let r = element.radius {
                        Text("Atomradius: ")
                        + Text("\(r) pm")
                            .fontWeight(.semibold)
                    }
                    Text("Elektronenkonfiguration: ")
                    + Text(element.orbitale)
                        .fontWeight(.semibold)
                    Text("Entdeckungsjahr: ")
                    + Text(element.entdeckt == -1 ? "Antik" : element.entdeckt.description)
                        .fontWeight(.semibold)
                }
            }
            if geladeneInhalte["szene"] == element.name {
                Section("3D-Modell"){
                    if let szene {
                        SceneView(scene: szene, options: [.autoenablesDefaultLighting,.allowsCameraControl])
                            .frame(height: 150)
                            .cornerRadius(10)
                            .overlay(arButton, alignment: .topTrailing)
                            .onTapGesture { print("") } // Ohne diesen Teil wird auf iOS der AR-Button nicht aktiviert
                    } else {
                        Text("Fehler: 3D Modell konnte nicht geladen werden.")
                    }
                }
            } else {
                Color.gray
                    .frame(height: 150)
                    .cornerRadius(10)
                    .redacted(reason: .placeholder)
                    .animierterPlatzhalter(isLoading: Binding.constant(true))
                    .task {
                        do {
                            let szene = try await NeoStorage.lade3dModell(fuer: element.name)
                            withAnimation {
                                self.szene = szene
                                self.geladeneInhalte["szene"] = element.name
                            }
                        } catch {
                            print(error)
                        }
                    }
            }
            if geladeneInhalte["texte"] == element.name {
                if !artikelSektionen.isEmpty {
                    ForEach(artikelSektionen) { sektion in
                        Section(sektion.titel) {
                            if let bild = sektion.bild() {
                                Image(uiImage: bild)
                            }
                            Text(sektion.text)
                        }.task {
                            // TODO: Lade eigenes Bild
                        }
                    }
                    if let textQuellen {
                        Section("Textquellen"){
                            ForEach(textQuellen, id: \.self) { quelle in
                                Text(quelle)
                            }
                        }
                    }
                    if let bildQuellen {
                        Section("Bildquellen"){
                            ForEach(bildQuellen, id: \.self) { quelle in
                                Text(quelle)
                            }
                        }
                    }
                } else {
                    Text("Fehler: Zu diesem Element scheint es noch keine Artikel zu geben.")
                }
            } else {
                Section {
                    VStack {
                        Color.gray
                            .frame(height: 150)
                            .cornerRadius(10)
                            .redacted(reason: .placeholder)
                            .animierterPlatzhalter(isLoading: Binding.constant(true))
                        Text("Beispieltext bei Spiel Texttext Bei SpielText. Bei Spieltexten spieltexte texten und spielen. Spiel texte Spiel Spieltexte bei texten und auch TextSpiel Text bei Text. Beispieltext bei Spiel Texttext Bei SpielText. Bei Spieltexten spieltexte texten und spielen. Spiel texte Spiel Spieltexte bei texten und auch TextSpiel Text bei Text.")
                            .redacted(reason: .placeholder)
                    }
                } header: {
                    Text("Sektionsname")
                        .redacted(reason: .placeholder)
                }.task {
                    let details = await NeoFire.ladeElementDetails(fuer: element)
                    artikelSektionen = details.0
                    textQuellen = details.1
                    bildQuellen = details.2
                    geladeneInhalte["texte"] = element.name
                }
            }
            if let wikiURL = konstruiereWikipediaURL(), UIApplication.shared.canOpenURL(konstruiereWikipediaURL() ?? URL.userDirectory) {
                Section {
                    Link(destination: wikiURL) {
                        HStack {
                            Image(systemName: "w.square.fill")
                                .scaleEffect(1.3)
                            Text("Wikipedia")
                            Spacer()
                            Image(systemName: "link")
                        }
                    }
                }
            }
        }
        .navigationTitle(element.name)
    }
    
    var arButton: some View {
        HStack {
            Text("In AR betrachten")
            Image(systemName: "dot.circle.viewfinder")
        }
        .foregroundColor(.white)
        .font(.system(size: 14))
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(.blue)
        .cornerRadius(10)
        .padding(5)
        .onTapGesture {
            url = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("modelle/\(element.name).usdz")
        }
        .quickLookPreview($url)
    }
    
    func konstruiereWikipediaURL() -> URL? {
        // Quelle: https://stackoverflow.com/questions/44754996/is-addingpercentencoding-broken-in-xcode-9
        // Nötig, damit das ':' in der URL nicht encoded wird
        let erlaubteBuchstaben = CharacterSet(bitmapRepresentation: CharacterSet.urlPathAllowed.bitmapRepresentation)
        guard let urlString = ("https://de.m.wikipedia.org/wiki/" + element.name).addingPercentEncoding(withAllowedCharacters: erlaubteBuchstaben) else {return nil}
        let url = URL(string: urlString)
        // Zu Titan gibt es mehrere Artikel, dort muss spezifiziert werden
        if element.name == "Titan" {
            return URL(string: "https://de.m.wikipedia.org/wiki/Titan_(Element)")
        }
        return url
    }
}

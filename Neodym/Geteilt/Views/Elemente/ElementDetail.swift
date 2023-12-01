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
        
    @State private var coverBild: UIImage?
    @State private var text: String?
    @State private var szene: SCNScene?
    @State private var artikelSektionen: [EArtikelSektion]?
    
    // Gibt an, ob der Ladeprozess für die jeweiligen Dateien abgeschlossen ist
    @State private var coverBildGeladen = false
    @State private var textGeladen = false
    @State private var szeneGeladen = false
    
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
                }
            }
            if szene != nil || !szeneGeladen {
                Section("3D-Modell"){
                    if !szeneGeladen {
                        Color.gray
                            .frame(height: 150)
                            .cornerRadius(10)
                            .redacted(reason: .placeholder)
                            .animierterPlatzhalter(isLoading: Binding.constant(true))
                    } else if let szene {
                        SceneView(scene: szene, options: [.autoenablesDefaultLighting,.allowsCameraControl])
                            .frame(height: 150)
                            .cornerRadius(10)
                            .overlay(arButton, alignment: .topTrailing)
                            .onTapGesture { print("") } // Ohne diesen Teil wird auf iOS der AR-Button nicht aktiviert
                    }
                }
            }
            if let artikelSektionen {
                ForEach(artikelSektionen) { sektion in
                    Section(sektion.titel){
                        
                    }
                }
            }
            Section{
                VStack {
                    if !coverBildGeladen {
                        Color.gray
                            .frame(height: 150)
                            .cornerRadius(10)
                            .redacted(reason: .placeholder)
                            .animierterPlatzhalter(isLoading: Binding.constant(true))
                    } else if let coverBild {
                        GeometryReader { geo in
                            Image(uiImage: coverBild)
                                .resizable()
                                .aspectRatio(coverBild.size, contentMode: .fill)
                                .frame(width: geo.size.width, height: 150)
                                .cornerRadius(10)
                        }.frame(height: 150)
                    } else {
                        Color.gray
                            .overlay(Text("Kein Bild gefunden :(").foregroundColor(.white))
                            .frame(height: 150)
                            .cornerRadius(10)
                    }
                    HStack {
                        if !textGeladen {
                            Text("Beispieltext bei Spiel Texttext Bei SpielText. Bei Spieltexten spieltexte texten und spielen. Spiel texte Spiel Spieltexte bei texten und auch TextSpiel Text bei Text.")
                                .redacted(reason: .placeholder)
                        } else if let text {
                            Text(text)
                        } else {
                            Text("Kein Infotext verfügbar :(")
                        }
                        Spacer()
                    }
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
        .task(priority: .background, {
            if let coverBild = await StorageManager.ladeBildFuer(element: element) {
                withAnimation {
                    self.coverBild = coverBild
                }
            }
            withAnimation { self.coverBildGeladen = true }
            if let szene = await StorageManager.lade3dModell(fuer: element.name) {
                withAnimation {
                    self.szene = szene
                    self.szeneGeladen = true
                }
            }
            withAnimation { self.szeneGeladen = true }
            if let text = await FirestoreManager.ladeText(fuer: element) {
                withAnimation {
                    self.text = text
                }
            }
            withAnimation { self.textGeladen = true }
        })
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

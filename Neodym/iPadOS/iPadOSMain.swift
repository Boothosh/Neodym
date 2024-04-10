//
//  iPadOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI
import CoreSpotlight

struct iPadOSMain: View {
    
    @Environment(NeoAuth.self) private var auth
    @Environment(Elemente.self) private var elemente
    @Environment(NeoStore.self) private var store
    
    @State private var ausgewaelterAppBereich: iPadAppBereich? = .elemente
    @State private var systemIstAusgewaelt = true
    
    @State private var suchBegriff = ""
    @State private var suche = false
    @State private var ausgewaeltesElement: Element? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var zeigeEinstellungen = false
    
    @AppStorage("sortiertNach") private var sortiertNach = "Ordnungszahl"
    @AppStorage("sortiertAufsteigend") private var sortiertAufsteigend = true
    
    //@State private var zeigePeriodenSystem = false
    
    @MainActor var elementListe: [Element] {
        elemente.alleElemente.filter({ element in
            element.name.lowercased().contains(suchBegriff.lowercased()) || element.symbol.lowercased().contains(suchBegriff.lowercased()) || suchBegriff == ""
        }).sorted {
            switch sortiertNach {
                case "Ordnungszahl":
                    return sortiertAufsteigend ? $0.kernladungszahl < $1.kernladungszahl : $0.kernladungszahl > $1.kernladungszahl
                case "Atomradius":
                    let r0 = $0.radius ?? 10000
                    let r1 = $1.radius ?? 10000
                    return sortiertAufsteigend ? r0 < r1 : r0 > r1
                case "Entdeckungsjahr":
                    return sortiertAufsteigend ? $0.entdeckt < $1.entdeckt : $0.entdeckt > $1.entdeckt
                case "Name":
                    return sortiertAufsteigend ? $0.name < $1.name : $0.name > $1.name
                default:
                    return false
            }
        }
    }
    
    var sideBar: some View {
        VStack {
            List(selection: $ausgewaelterAppBereich){
                FTLabel("Elemente", bild: "pse", scale: 0.8)
                    .tag(iPadAppBereich.elemente)
                DisclosureGroup(content: {
                    FTLabel("Stöchiometrie", bild: "stoechiometrie", scale: 0.8)
                        .tag(iPadAppBereich.wissen_stoechometrie)
                }, label: {
                    FTLabel("Wissen", bild: "wissen", scale: 0.8)
                })
                DisclosureGroup(content: {
                    FTLabel("Moleküle zeichnen", bild: "canvas", scale: 0.8)
                        .tag(iPadAppBereich.werkzeug_zeichnen)
                    FTLabel("Molekülmasse ausrechnen", bild: "wage", scale: 0.8)
                        .tag(iPadAppBereich.werkzeug_molmasse)
                    FTLabel("Ionengruppe bilden", bild: "ionengitter", scale: 0.8)
                        .tag(iPadAppBereich.werkzeug_ionengruppe)
                }, label: {
                    FTLabel("Werkzeuge", bild: "werkzeuge", scale: 0.8)
                })
                FTLabel("Quiz", bild: "quiz", scale: 0.8)
                    .tag(iPadAppBereich.quiz)
                if auth.email != nil {
                    FTLabel("Lizenzen", bild: "lizenzen", scale: 0.8)
                        .tag(iPadAppBereich.lizenzen)
                }
            }
            VStack(spacing: 0){
                Button {
                    zeigeEinstellungen = true
                } label: {
                    HStack {
                        Text("Einstellungen")
                        Spacer()
                        Image("einstellungen")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }.padding()
                        .background(.indigo)
                        .cornerRadius(10)
                        .padding(5)
                }.foregroundStyle(.white)
            }
        }.navigationTitle("Neodym")
            .sheet(isPresented: $zeigeEinstellungen, content: {
                Einstellungen()
                    .environment(elemente)
                    .environment(auth)
                    .environment(store)
            })
            .ignoresSafeArea(.keyboard)
    }
    
    @MainActor var hauptcontent: some View {
        VStack {
            switch ausgewaelterAppBereich {
                case .elemente:
                    VStack(alignment: .center){
                        if elemente.perioden.isEmpty {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else if systemIstAusgewaelt {
                            System(suchBegriff: $suchBegriff, ausgewaeltesElement: $ausgewaeltesElement)
                                .environment(elemente)
                                .navigationTitle("Elemente")
                        } else {
                            // DetailView wegen Liste
                            if let ausgewaeltesElement {
                                ElementDetail(element: ausgewaeltesElement)
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem {
                            Picker("Ansicht", selection: $systemIstAusgewaelt.onChange(setzteNeuenSystemIstAusgewaeltWert)) {
                                Text("Periodensystem").tag(true)
                                Text("Liste").tag(false)
                            }
                            .pickerStyle(.segmented)
                        }
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
                                        
                                    }
                                    Divider()
                                    Picker(selection: $sortiertAufsteigend) {
                                        Text("Aufsteigend")
                                            .tag(true)
                                        Text("Absteigend")
                                            .tag(false)
                                    } label: {
                                        
                                    }
                                }
                            }
                        }
                    }
                case .wissen_stoechometrie:
                    Wissen()
                case .wissen_molekuele:
                    Wissen()
                case .werkzeug_zeichnen:
                    Molekuelzeichner()
                        .environment(elemente)
                case .werkzeug_molmasse:
                    MolekuelmasseRechner()
                        .environment(elemente)
                case .werkzeug_ionengruppe:
                    IonengruppenBilden()
                        .environment(elemente)
                case .quiz:
                    QuizView()
                case .lizenzen:
                    LizenzenUebersicht()
                        .environment(auth)
                        .environment(store)
                case nil:
                    Text("Wähle einen Bereich der App aus, den du nutzen möchtest!")
            }
        }
    }
    
    func setzteNeuenSystemIstAusgewaeltWert(_ neuerWert: Bool) {
        Task {
            if neuerWert {
                if columnVisibility == .doubleColumn {
                    columnVisibility = .detailOnly
                }
                ausgewaeltesElement = nil
            } else {
                if columnVisibility == .detailOnly {
                    columnVisibility = .doubleColumn
                }
                let erstesElement = await elemente.alleElemente.first!
                withAnimation {
                    ausgewaeltesElement = erstesElement
                }
            }
        }
    }
    
    var body: some View {
        if ausgewaelterAppBereich == .elemente && !systemIstAusgewaelt {
            NavigationSplitView(columnVisibility: $columnVisibility){
                sideBar
            } content: {
                List(elementListe, id: \.self, selection: $ausgewaeltesElement){ element in
                    HStack{
                        Text(element.symbol)
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.bold)
                            .shadow(radius: 5)
                            .frame(width: 60, height: 60)
                            .background(Color(element.klassifikation).gradient)
                            .cornerRadius(5)
                            .overlay(alignment: .bottomTrailing){
                                Text(element.kernladungszahl.description)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(3)
                                    .padding(.trailing, 2)
                            }
                            .shadow(radius: 5)
                            .padding(.trailing)
                        VStack(alignment: .leading){
                            Text(element.name)
                                .font(.title3)
                                .foregroundStyle(.prim)
                            let text = (sortiertNach == "Atomradius") ? "Atomradius: \(element.radius != nil ? element.radius!.description + " pm" : "Unbekannt")" : (sortiertNach == "Entdeckungsjahr") ? "Entdeckungsjahr: \(element.entdeckt == -1 ? "Antik" : element.entdeckt.description)" : element.klassifikation
                            Text(text)
                                .fontWeight(.bold)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .animation(.easeIn, value: elementListe)
                .searchable(text: $suchBegriff, isPresented: $suche)
                .navigationTitle("Elemente")
            } detail: {
                hauptcontent
            }
            .onContinueUserActivity(CSSearchableItemActionType, perform: spotlight)
            .onContinueUserActivity(CSQueryContinuationActionType, perform: spotlightSuche)
            
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility){
                sideBar
            } detail: {
                hauptcontent
            }
            .onContinueUserActivity(CSSearchableItemActionType, perform: spotlight)
            .onContinueUserActivity(CSQueryContinuationActionType, perform: spotlightSuche)
        }
    }
    
    enum iPadAppBereich: Hashable {
        case elemente
        case wissen_stoechometrie, wissen_molekuele
        case werkzeug_zeichnen, werkzeug_molmasse, werkzeug_ionengruppe
        case quiz
        case lizenzen
    }
    
    @MainActor func spotlight(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }
        if let element = elemente.alleElemente.first(where: { $0.name == searchString }) {
            ausgewaeltesElement = element
            ausgewaelterAppBereich = .elemente
        }
    }
    
    func spotlightSuche(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchQueryString] as? String else { return }
        ausgewaelterAppBereich = .elemente
        suche = true
        suchBegriff = searchString
    }
}

// Wokraround, weil .onChange nicht normal gecallt wird
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { selection in
                self.wrappedValue = selection
                handler(selection)
            })
    }
}

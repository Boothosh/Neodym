//
//  iPadOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI
import CoreSpotlight

struct iPadRoot: View {
    
    @Environment(NeoAuth.self) private var auth
    @Environment(Elemente.self) private var elemente
    @Environment(NeoStore.self) private var store
    
    @State private var ausgewaelterAppBereich: SideBarAppBereich? = .elemente
    
    @State private var suchBegriff = ""
    @State private var suche = false
    
    @State private var ausgewaeltesElement: Element? = nil
    @State private var navigationPath = NavigationPath()
    @State private var systemIstAusgewaelt = true
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var zeigeEinstellungen = false
    
    var sideBar: some View {
        VStack {
            List(selection: $ausgewaelterAppBereich){
                Label("Elemente", image: .periodensystem)
                    .tag(SideBarAppBereich.elemente)
                DisclosureGroup(content: {
                    Label("Stöchiometrie", systemImage: "function")
                        .tag(SideBarAppBereich.stoechometrie)
                }, label: {
                    Label("Wissen", systemImage: "books.vertical.fill")
                })
                DisclosureGroup(content: {
                    Label("Moleküle zeichnen", image: .canvas)
                        .tag(SideBarAppBereich.canvas)
                    Label("Molekülmasse ausrechnen", systemImage: "scalemass.fill")
                        .tag(SideBarAppBereich.molmasse)
                    Label("Salze bilden", image: .salz)
                        .tag(SideBarAppBereich.ionengruppe)
                }, label: {
                    Label("Werkzeuge", systemImage: "wrench.and.screwdriver.fill")
                })
                Label("Quiz", systemImage: "brain.fill")
                    .tag(SideBarAppBereich.quiz)
                if auth.email != nil {
                    Label("Lizenzen", systemImage: "key.fill")
                        .tag(SideBarAppBereich.lizenzen)
                }
            }
            .frame(minWidth: 175)
            #if os(iOS)
            .onChange(of: ausgewaelterAppBereich) { _, newValue in
                if newValue == .canvas {
                    Task {
                        usleep(500_000)
                        columnVisibility = .detailOnly
                    }
                }
            }
            #endif
            #if os(iOS) || os(visionOS)
            VStack(spacing: 0){
                Button {
                    zeigeEinstellungen = true
                } label: {
                    HStack {
                        Text("Einstellungen")
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "gearshape.2.fill")
                    }.padding()
                        .background(.indigo)
                        .cornerRadius(10)
                        .padding(5)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
            }
            #endif
        }
        #if os(iOS) || os(visionOS)
            .navigationTitle("Neodym")
            .sheet(isPresented: $zeigeEinstellungen, content: {
                Einstellungen()
                    .environment(elemente)
                    .environment(auth)
                    .environment(store)
            })
            .ignoresSafeArea(.keyboard)
        #endif
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
                        } else {
                            ElementeUeberblick(systemIstAusgewaelt: $systemIstAusgewaelt, suchBegriff: $suchBegriff, sucheAktiv: $suche, ausgewaeltesElement: $ausgewaeltesElement, navigationPath: $navigationPath)
                                .environment(elemente)
                        }
                    }
                case .stoechometrie:
                    Wissen()
                case .molekuele:
                    Wissen()
                case .canvas:
                    Molekuelzeichner(columnVisibility: $columnVisibility)
                        .environment(elemente)
                case .molmasse:
                    MolekuelmasseRechner()
                        .environment(elemente)
                case .ionengruppe:
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
        
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility){
            sideBar
                .frame(minWidth: 250)
        } detail: {
            hauptcontent
        }
        .onContinueUserActivity(CSSearchableItemActionType, perform: spotlight)
        .onContinueUserActivity(CSQueryContinuationActionType, perform: spotlightSuche)
    }
    
    @MainActor func spotlight(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }
        if let element = elemente.alleElemente.first(where: { $0.name == searchString }) {
            ausgewaelterAppBereich = .elemente
            if systemIstAusgewaelt {
                ausgewaeltesElement = element
            } else {
                navigationPath.append(element)
            }
        }
    }
    
    func spotlightSuche(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchQueryString] as? String else { return }
        ausgewaelterAppBereich = .elemente
        suche = true
        suchBegriff = searchString
        // Nur um sicherzugehen
        navigationPath.removeLast(5)
        ausgewaeltesElement = nil
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

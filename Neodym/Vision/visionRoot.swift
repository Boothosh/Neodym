//
//  visionRoot.swift
//  Neodym
//
//  Created by Max Eckstein on 02.05.24.
//

import SwiftUI
import CoreSpotlight

#if os(visionOS)
struct visionRoot: View {
    
    @Environment(NeoStore.self) var store
    @Environment(NeoAuth.self) var auth
    @Environment(Elemente.self) var elemente
    
    @State private var bereich: TabAppBereich = .elemente
    
    @State private var suchBegriff = ""
    @State private var suche = false
    
    @State private var ausgewaeltesElement: Element? = nil
    @State private var navigationPath = NavigationPath()
    @State private var systemIstAusgewaelt = true
    
    var body: some View {
        TabView {
            VStack(alignment: .center){
                if elemente.perioden.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    NavigationStack {
                        ElementeUeberblick(systemIstAusgewaelt: $systemIstAusgewaelt, suchBegriff: $suchBegriff, sucheAktiv: $suche, ausgewaeltesElement: $ausgewaeltesElement, navigationPath: $navigationPath)
                                .environment(elemente)
                    }
                }
            }
                .tabItem { Label("Periodensystem", image: "periodensystem") }
                .tag(TabAppBereich.elemente)
            Text("Wissen")
                .tabItem { Label("Wissen", systemImage: "books.vertical.fill") }
                .tag(TabAppBereich.wissen)
            NavigationStack {
                Werkzeuge()
                    .environment(elemente)
            }
                .tabItem { Label("Werkzeuge", systemImage: "wrench.and.screwdriver.fill") }
                .tag(TabAppBereich.werkzeuge)
            QuizView()
                .tabItem { Label("Quiz", systemImage: "brain.fill") }
                .tag(TabAppBereich.quiz)
//            Text("Lizenzen")
//                .tabItem { Label("Lizenzen", systemImage: "key.fill") }
//                .tag(TabAppBereich.lizenzen)
            Einstellungen()
                .environment(store)
                .environment(auth)
                .environment(elemente)
                .tabItem { Label("Einstellungen", systemImage: "gearshape.2.fill") }
                .tag(TabAppBereich.einstellungen)
        }
        .onContinueUserActivity(CSSearchableItemActionType, perform: spotlight)
        .onContinueUserActivity(CSQueryContinuationActionType, perform: spotlightSuche)
    }
    
    @MainActor func spotlight(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return
        }
        if let element = elemente.alleElemente.first(where: { $0.name == searchString }) {
            bereich = .elemente
            if systemIstAusgewaelt {
                ausgewaeltesElement = element
            } else {
                navigationPath.append(element)
            }
        }
    }
    
    func spotlightSuche(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchQueryString] as? String else { return }
        bereich = .elemente
        suche = true
        suchBegriff = searchString
        // Nur um sicherzugehen
        navigationPath.removeLast(5)
        ausgewaeltesElement = nil
    }
    
}
#endif

//
//  iOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI
import CoreSpotlight

struct iOSMain: View {
    
    @Environment(NeoAuth.self) private var auth
    @Environment(Elemente.self) private var elemente
    @Environment(NeoStore.self) private var store
    
    @State private var appBereich = "Elemente"
    
    // Für Elementliste
    @State var suche = false
    @State var suchBegriff = ""
    @State var navigationVonElementListe = NavigationPath()
    
    var body: some View {
        TabView(selection: $appBereich){
            iOSElementListe(navigationPfad: $navigationVonElementListe, suchBegriff: $suchBegriff, suche: $suche)
                .environment(elemente)
                .tabItem {
                    Label("Elemente", systemImage: "atom")
                }.tag("Elemente")
            NavigationStack {
                Wissen()
            }
            .tabItem {
                Label("Wissen", systemImage: "graduationcap")
                    .environment(\.symbolVariants, .none) // Um zu verhindern, dass Icon gefüllt wird
            }.tag("Wissen")
            NavigationStack{
                Werkzeuge()
                    .environment(elemente)
            }
            .tabItem {
                Label("Werkzeuge", systemImage: "wrench.and.screwdriver")
            }.tag("Werkzeuge")
            // QuizView ist in der 1.0 Version für iPhones deaktiviert, da noch nicht ausgereift
//            NavigationStack {
//                QuizView()
//            }
//            .tabItem {
//                Label("Quiz", systemImage: "brain")
//                    .environment(\.symbolVariants, .none) // Um zu verhindern, dass Icon gefüllt wird/
//            }.tag("Quiz")
            if auth.email != nil {
                NavigationStack {
                    LizenzenKaufen()
                }.tabItem { Label("Lizenzen", systemImage: "key").environment(\.symbolVariants, .none) }
                    .tag("Lizenzen")
            }
            Einstellungen()
                .environment(elemente)
                .environment(auth)
                .environment(store)
                .tabItem {
                Label("Einstellungen", systemImage: "gearshape.2")
                    .environment(\.symbolVariants, .none) // Um zu verhindern, dass Icon gefüllt wird/
            }.tag("Einstellungen")
        }.onContinueUserActivity(CSSearchableItemActionType, perform: spotlight)
            .onContinueUserActivity(CSQueryContinuationActionType, perform: spotlightSuche)
    }
    
    func spotlight(userActivity: NSUserActivity) {
        Task {
            guard let searchString = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return
            }
            if let element = await elemente.alleElemente.first(where: { $0.name == searchString }) {
                navigationVonElementListe.append(element)
                appBereich = "Elemente"
            }
        }
     }
    
    func spotlightSuche(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchQueryString] as? String else { return }
        suche = true
        suchBegriff = searchString
        appBereich = "Elemente"
        navigationVonElementListe.removeLast(5) // Nur um sicher zu gehen
    }
}

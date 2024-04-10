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
    
    @State private var appBereich = AppBereich.elemente
    
    // Für Elementliste
    @State var suche = false
    @State var suchBegriff = ""
    @State var navigationVonElementListe = NavigationPath()
    
    var body: some View {
        VStack(spacing: 0) {
            // Ausgewählter Inhalt
            switch appBereich {
                case .elemente:
                    iOSElementListe(navigationPfad: $navigationVonElementListe, suchBegriff: $suchBegriff, suche: $suche)
                        .environment(elemente)
                case .wissen:
                    NavigationStack {
                        Wissen()
                    }
                case .werkzeuge:
                    NavigationStack {
                        Werkzeuge()
                            .environment(elemente)
                    }
                case .lizenzen:
                    NavigationStack {
                        LizenzenUebersicht()
                            .environment(store)
                            .environment(auth)
                    }
                case .einstellungen:
                    Einstellungen()
                        .environment(elemente)
                        .environment(auth)
                        .environment(store)
            }
            // Tabbar
            Divider()
                .background(.indigo)
            GeometryReader { geo in
                let w = (geo.size.width - ((auth.email == nil) ? 3 : 4) * 10) / CGFloat((auth.email == nil) ? 4.0 : 5.0)
                HStack {
                    TabItem(.elemente, w)
                    Spacer()
                    TabItem(.wissen, w)
                        .frame(width: 65)
                    Spacer()
                    TabItem(.werkzeuge, w)
                        .frame(width: 65)
                    if auth.email != nil {
                        Spacer()
                        TabItem(.lizenzen, w)
                            .frame(width: 65)
                    }
                    Spacer()
                    TabItem(.einstellungen, w)
                }
            }
            .frame(height: 50)
            .padding(.horizontal)
            .padding(.top)
            .background(.quinary)
        }
        .onContinueUserActivity(CSQueryContinuationActionType, perform: spotlightSuche)
        .onContinueUserActivity(CSSearchableItemActionType, perform: spotlight)
        .sensoryFeedback(.selection, trigger: appBereich)
    }
    
    func spotlight(userActivity: NSUserActivity) {
        Task {
            guard let searchString = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
                return
            }
            if let element = await elemente.alleElemente.first(where: { $0.name == searchString }) {
                navigationVonElementListe.append(element)
                appBereich = .elemente
            }
        }
    }
    
    func spotlightSuche(userActivity: NSUserActivity) {
        guard let searchString = userActivity.userInfo?[CSSearchQueryString] as? String else { return }
        suche = true
        suchBegriff = searchString
        appBereich = .elemente
        navigationVonElementListe.removeLast(5) // Nur um sicher zu gehen
    }
    
    enum AppBereich: String {
        case elemente =         "Elemente"
        case wissen =           "Wissen"
        case werkzeuge =        "Werkzeuge"
        case lizenzen =         "Lizenzen"
        case einstellungen =    "Einstellungen"
    }
    
    func TabItem(_ name: AppBereich, _ width: CGFloat) -> some View {
        VStack {
            Image(name.rawValue.lowercased())
                .resizable()
                .frame(width: 25, height: 25)
            Text(name.rawValue)
                .font(.caption2)
                .foregroundStyle(appBereich == name ? .indigo : .primary)
        }.onTapGesture {
            appBereich = name
        }.frame(width: width)
    }
}

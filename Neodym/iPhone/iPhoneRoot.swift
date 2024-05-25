//
//  iOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI
import CoreSpotlight

#if os(iOS)
struct iPhoneRoot: View {
    
    @Environment(NeoAuth.self) private var auth
    @Environment(Elemente.self) private var elemente
    @Environment(NeoStore.self) private var store
    
    @State private var appBereich: TabAppBereich = .elemente
    @State private var appBereichAnimationen: [TabAppBereich: Int] = [:]
    
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
                case .quiz:
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
                case .lizenzen:
                    Text("Lizenzen werden hier nicht angezeigt")
            }
            // Tabbar
            Divider()
                .background(Color.secondary)
            GeometryReader { geo in
                let width = geo.size.width / CGFloat(5.0)
                HStack(spacing: 0){
                    VStack {
                        Image("periodensystem")
                            .foregroundStyle(appBereich != .elemente ? Color.secondary : .green, appBereich != .elemente ? Color.secondary : .blue, appBereich != .elemente ? Color.secondary : .orange)
                            .symbolEffect(.bounce, value: appBereichAnimationen[.elemente] ?? 0)
                            .frame(width: 25, height: 25)
                        Text("Elemente")
                            .font(.system(size: 10))
                            .foregroundStyle(appBereich == .elemente ? .indigo : Color.secondary)
                    }.onTapGesture {
                        appBereich = .elemente
                        appBereichAnimationen[.elemente] = Int.random(in: 1...99999)
                    }
                    .frame(width: width)
                    VStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundStyle(appBereich != .wissen ? Color.secondary : .indigo)
                            .symbolEffect(.bounce, value: appBereichAnimationen[.wissen] ?? 0)
                            .frame(width: 25, height: 25)
                        Text("Wissen")
                            .font(.system(size: 10))
                            .foregroundStyle(appBereich == .wissen ? .indigo : Color.secondary)
                    }.onTapGesture {
                        appBereich = .wissen
                        appBereichAnimationen[.wissen] = Int.random(in: 1...99999)
                    }
                    .frame(width: width)
                    VStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundStyle(appBereich != .werkzeuge ? Color.secondary : .green, appBereich != .werkzeuge ? Color.secondary : .indigo)
                            .symbolEffect(.bounce, value: appBereichAnimationen[.werkzeuge] ?? 0)
                            .frame(width: 25, height: 25)
                        Text("Werkzeuge")
                            .font(.system(size: 10))
                            .foregroundStyle(appBereich == .werkzeuge ? .indigo : Color.secondary)
                    }.onTapGesture {
                        appBereich = .werkzeuge
                        appBereichAnimationen[.werkzeuge] = Int.random(in: 1...99999)
                    }
                    .frame(width: width)
                    VStack {
                        Image(systemName: "brain.fill")
                            .foregroundStyle(appBereich != .quiz ? Color.secondary : .indigo)
                            .symbolEffect(.bounce, value: appBereichAnimationen[.quiz] ?? 0)
                            .frame(width: 25, height: 25)
                        Text("Quiz")
                            .font(.system(size: 10))
                            .foregroundStyle(appBereich == .quiz ? .indigo : Color.secondary)
                    }.onTapGesture {
                        appBereich = .quiz
                        appBereichAnimationen[.quiz] = Int.random(in: 1...99999)
                    }
                    .frame(width: width)
                    VStack {
                        Image(systemName: "gearshape.2.fill")
                            .foregroundStyle(appBereich != .einstellungen ? Color.secondary : .indigo)
                            .symbolEffect(.bounce, value: appBereichAnimationen[.einstellungen] ?? 0)
                            .frame(width: 25, height: 25)
                        Text("Einstellungen")
                            .font(.system(size: 10))
                            .foregroundStyle(appBereich == .einstellungen ? .indigo : Color.secondary)
                    }.onTapGesture {
                        appBereich = .einstellungen
                        appBereichAnimationen[.einstellungen] = Int.random(in: 1...99999)
                    }
                    .frame(width: width)
                }
            }
            .frame(height: 50)
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
}
#endif

//
//  visionRoot.swift
//  Neodym
//
//  Created by Max Eckstein on 02.05.24.
//

import SwiftUI

#if os(visionOS)
struct visionRoot: View {
    
    @Environment(NeoStore.self) var store
    @Environment(NeoAuth.self) var auth
    @Environment(Elemente.self) var elemente
    
    @State private var bereich: TabAppBereich = .elemente
    
    var body: some View {
        TabView {
            Text("Periodensystem und Liste")
                .tabItem { Label("Periodensystem", image: "periodensystem") }
                .tag(TabAppBereich.elemente)
            Text("Wissen")
                .tabItem { Label("Wissen", systemImage: "books.vertical.fill") }
                .tag(TabAppBereich.wissen)
            Text("Werkzeuge")
                .tabItem { Label("Werkzeuge", systemImage: "wrench.and.screwdriver.fill") }
                .tag(TabAppBereich.werkzeuge)
            QuizView()
                .tabItem { Label("Quiz", systemImage: "brain.fill") }
                .tag(TabAppBereich.quiz)
            Text("Lizenzen")
                .tabItem { Label("Lizenzen", systemImage: "key.fill") }
                .tag(TabAppBereich.lizenzen)
            Einstellungen()
                .environment(store)
                .environment(auth)
                .environment(elemente)
                .tabItem { Label("Einstellungen", systemImage: "gearshape.2.fill") }
                .tag(TabAppBereich.einstellungen)
        }
    }
    
}
#endif

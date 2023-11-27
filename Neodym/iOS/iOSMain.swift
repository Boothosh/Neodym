//
//  iOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI

struct iOSMain: View {
    
    @Binding var elementeManager: ElementManager
    
    var body: some View {
        TabView {
            NavigationStack {
                iOSElementListe(elementeManager: $elementeManager)
            }.tabItem {
                Label("Elemente", systemImage: "atom")
            }
            NavigationStack {
                Wissen()
            }
            .tabItem {
                Label("Wissen", systemImage: "graduationcap")
                    .environment(\.symbolVariants, .none) // Um zu verhindern, dass Icon gefüllt wird
            }
            NavigationStack{
                Werkzeuge(elementeManager: $elementeManager)
            }
            .tabItem {
                Label("Werkzeuge", systemImage: "wrench.and.screwdriver")
            }
            NavigationStack {
                QuizView()
            }
            .tabItem {
                Label("Quiz", systemImage: "brain")
                    .environment(\.symbolVariants, .none) // Um zu verhindern, dass Icon gefüllt wird/
            }
            Einstellungen().tabItem {
                Label("Einstellungen", systemImage: "gearshape.2")
                    .environment(\.symbolVariants, .none) // Um zu verhindern, dass Icon gefüllt wird/
            }
        }
        .task {
            await elementeManager.ladeDatei()
        }
    }
}

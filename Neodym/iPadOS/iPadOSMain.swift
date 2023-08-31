//
//  iPadOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI

struct iPadOSMain: View {
    
    @Binding var elementeManager: ElementManager
    @State private var ausgewaelterAppBereich: String? = "Elemente"
    
    var body: some View {
        NavigationSplitView(sidebar: {
            List(selection: $ausgewaelterAppBereich){
                Label("Elemente", systemImage: "atom")
                    .tag("Elemente")
                Label("Wissen", systemImage: "graduationcap")
                    .tag("Wissen")
                Label("Werkzeuge", systemImage: "wrench.and.screwdriver")
                    .tag("Werkzeuge")
                Label("Quiz", systemImage: "brain")
                    .tag("Quiz")
                Label("Einstellungen", systemImage: "gearshape.2")
                    .tag("Einstellungen")
            }.navigationTitle("Neodym")
        }) {
            NavigationStack {
                switch ausgewaelterAppBereich {
                    case "Elemente":
                        ElementeBetrachter(elementeManager: $elementeManager)
                    case "Wissen":
                        Wissen()
                    case "Werkzeuge":
                        Werkzeuge(elementeManager: $elementeManager)
                    case "Quiz":
                        QuizView()
                    case "Einstellungen":
                        Einstellungen()
                    default:
                        Text("Wähle einen Bereich der App aus, den du nutzen möchtest!")
                }
            }
        }.task {
            await elementeManager.ladeDatei()
        }
    }
}

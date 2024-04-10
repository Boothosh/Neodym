//
//  InfoSheet.swift
//  Neodym
//
//  Created by Max Eckstein on 02.04.24.
//

import SwiftUI

struct InfoSheet: View {
    
    let text: String
    let titel: String
    
    init(_ titel: String, _ text: InfoTextTyp) {
        self.titel = titel
        self.text = text.rawValue
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading){
                    HStack {
                        Text("\(Image(systemName: "info.circle")) Information")
                            .font(.caption2)
                        Spacer()
                    }
                    Divider()
                        .background(.indigo)
                    Text(text)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 23)
            }.navigationTitle(titel)
        }
    }
    
}

enum InfoTextTyp: String {
    case lizenzen = "Um einer Gruppe von Schüler:innen zu ermöglichen, dass sie die Neodym App im Rahmen des Chemieunterrichts benutzen kann, müssen Sie Lizenzen kaufen. Jede Lizenz schaltet Neodym für ein Jahr auf einem Gerät frei.\n\nDas Jahr, in welchem eine Lizenz gültig ist, startet mit der ersten Anmeldung eines/einer Schülers/Schülerin mit dieser Lizenz. Wenn sich der Schüler/die Schülerin wieder abmeldet, kann sich auf einem anderen Gerät mit dieser Lizenz angemeldet werden. Allerdings läuft das Jahr, auch wenn niemand mehr mit der Lizenz angemeldet ist, weiter ab.\n\nDamit Ihre Schüler:innen sich mit den von Ihnen gekauften Lizenzen anmelden können, müssen Sie ihnen die Lizenz-Schlüssel geben. Ihre Schüler:innen können sich dann in der App unter „Alternative Anmeldemethoden“ als Schüler:innen mit ihrer Lizenz anmelden."
}

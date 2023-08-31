//
//  Werkzeuge.swift
//  Neodym
//
//  Created by Max Eckstein on 13.07.23.
//

import SwiftUI

struct Werkzeuge: View {
    @Binding var elementeManager: ElementManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 20)], spacing: 20) {
                kachel(titel: "Moleküle\nzeichnen", symbol: "pencil.and.ruler", farbe: .mint, ziel: Molekuelzeichner(elementeManager: $elementeManager))
                kachel(titel: "Molekülmasse\nausrechnen", symbol: "scalemass", farbe: .green, ziel: MolekuelmasseRechner(elementManager: $elementeManager))
                kachel(titel: "Ionengruppe\nbilden", symbol: "circle.grid.3x3", farbe: .yellow, ziel: IonengruppenBilden(elementManager: $elementeManager))
                kachel(titel: "Gleichungen\nausgleichen", symbol: "arrow.left.arrow.right.circle", farbe: .blue, ziel: GleichungenAusgleichen(), verfuegbar: false)
                kachel(titel: "Unbekannte\nGröße bestimmen", symbol: "sum", farbe: .orange, ziel: GroesseBestimmen(), verfuegbar: false)
            }.padding()
        }
            .navigationTitle("Werkzeuge")
    }
    
    func kachel(titel: String, symbol: String, farbe: Color, ziel: some View, verfuegbar: Bool = true) -> some View {
        NavigationLink(destination: ziel){
            VStack(alignment: .leading){
                Spacer()
                HStack {
                    Text(titel)
                        .font(.system(size: 32, weight: .black))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: symbol)
                        .font(.system(size: 64, weight: .thin))
                }
                    .foregroundColor(.white)
                if !verfuegbar {
                    Text("Kommt bald!")
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal)
            .background(verfuegbar ? farbe.gradient : Color.gray.gradient)
            .aspectRatio(CGSize(width: 2, height: 1), contentMode: .fill)
            .cornerRadius(25)
        }.disabled(!verfuegbar)
    }
}

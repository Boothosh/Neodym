//
//  Werkzeuge.swift
//  Neodym
//
//  Created by Max Eckstein on 13.07.23.
//

import SwiftUI

struct Werkzeuge: View {
    
    @Environment(Elemente.self) private var elemente
    
    var body: some View {
        ScrollView {
            werkzeugVorschauKachel("Moleküle\nzeichnen", "canvas", .mint, ziel: Molekuelzeichner(columnVisibility: .constant(.detailOnly)).environment(elemente) , eigenesIcon: true)
            werkzeugVorschauKachel("Molekülmasse\nausrechnen", "scalemass", .green, ziel: MolekuelmasseRechner().environment(elemente))
            werkzeugVorschauKachel("Ionengruppe\nbilden", "salz", .yellow, ziel: IonengruppenBilden().environment(elemente), eigenesIcon: true)
            werkzeugVorschauKachel("Gleichungen\nausgleichen", "arrow.left.arrow.right.circle", .blue, ziel: GleichungenAusgleichen(), verfuegbar: false)
            werkzeugVorschauKachel("Unbekannte\nGröße bestimmen", "sum", .orange, ziel: GroesseBestimmen(), verfuegbar: false)
        }
            .navigationTitle("Werkzeuge")
    }
    
    func werkzeugVorschauKachel(_ titel: String, _ symbol: String, _ farbe: Color, ziel: some View, verfuegbar: Bool = true, eigenesIcon: Bool = false) -> some View {
        NavigationLink(destination: ziel){
            VStack(alignment: .leading, spacing: 0){
                if !verfuegbar {
                    Text("Kommt bald!")
                        .frame(height: 24)
                        .padding(.horizontal, 5)
                        .background(.green)
                        .foregroundStyle(.white)
                        .cornerRadius(5)
                        .offset(x: 15, y: 15)
                        .zIndex(1)
                }
                HStack {
                    Text(titel)
                        .font(.system(size: 32, weight: .black))
                        .multilineTextAlignment(.leading)
                    Spacer()
                    if !eigenesIcon {
                        Image(systemName: symbol)
                            .font(.system(size: 64))
                    } else {
                        Image(symbol)
                            .font(.system(size: 64))
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(verfuegbar ? farbe.gradient : Color.gray.gradient)
                .cornerRadius(25)
                .zIndex(0.1)
            }
        }.disabled(!verfuegbar)
        .padding(.horizontal)
    }
}

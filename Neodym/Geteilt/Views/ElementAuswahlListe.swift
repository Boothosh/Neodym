//
//  ElementAuswahlListe.swift
//  Neodym
//
//  Created by Max Eckstein on 12.07.23.
//

import SwiftUI

struct ElementAuswahlListe: View {
    
    @Environment(Elemente.self) private var elemente
    @Environment(\.dismiss) var schließen
    
    @State var suchBegriff = ""
    let hinzufuegen: (Element)->(Void)
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(elemente.alleElemente.filter({ element in
                    element.name.lowercased().contains(suchBegriff.lowercased()) || element.symbol.lowercased().contains(suchBegriff.lowercased()) || suchBegriff == ""
                })) { element in
                    HStack {
                        Text(element.symbol)
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.bold)
                            .shadow(radius: 5)
                            .frame(width: 60, height: 60)
                            .background(Color(element.klassifikation))
                            .cornerRadius(5)
                            .shadow(radius: 5)
                            .padding(.trailing)
                        VStack(alignment: .leading){
                            Text(element.name)
                                .font(.title3)
                            Text(element.klassifikation)
                                .fontWeight(.bold)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .onTapGesture {
                        hinzufuegen(element)
                        schließen()
                    }
                }
            }
            .searchable(text: $suchBegriff)
            .navigationTitle("Element auswählen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

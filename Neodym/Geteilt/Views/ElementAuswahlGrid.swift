//
//  ElementAuswahlGrid.swift
//  Neodym
//
//  Created by Max Eckstein on 03.10.23.
//

import SwiftUI

struct ElementAuswahlGrid: View {
    
    @Environment(Elemente.self) private var elemente
    
    @State var suchBegriff = ""
    @Environment(\.dismiss) var schließen
    let hinzufuegen: (Element)->(Void)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 8) {
                    ForEach(elemente.alleElemente.filter({ element in
                        element.name.lowercased().contains(suchBegriff.lowercased()) || element.symbol.lowercased().contains(suchBegriff.lowercased()) || suchBegriff == ""
                    })) { element in
                        Text(element.symbol)
                            .font(.system(size: 18, weight: .black))
                            .shadow(radius: 5)
                            .padding(5)
                            .frame(width: 60, height: 65)
                            .background(Color(element.klassifikation).gradient)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                            .onTapGesture {
                                hinzufuegen(element)
                                schließen()
                            }
                    }
                }.padding()
            }
            .navigationTitle("Element auswählen")
            #if os(iOS) || os(visionOS)
            .searchable(text: $suchBegriff, placement: .navigationBarDrawer(displayMode: .always), prompt: "Suchen...")
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
        .frame(minWidth: UIDevice.current.userInterfaceIdiom == .phone ? 0 : 450, minHeight: UIDevice.current.userInterfaceIdiom == .phone ? 0 : 350)
        #else
        .frame(minWidth: 450, minHeight: 350)
        #endif
    }
}

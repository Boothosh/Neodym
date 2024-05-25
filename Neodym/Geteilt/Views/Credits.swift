//
//  Credits.swift
//  Neodym
//
//  Created by Max Eckstein on 19.03.24.
//

import SwiftUI

struct Credits: View {
    var body: some View {
        List {
            Section("Bildquellen"){
                HStack{
                    Image(.aetzend)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-acid.svg")
                        .font(.caption)
                }
                HStack{
                    Image(.brandfoerdernd)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-rondflam.svg")
                        .font(.caption)
                }
                HStack{
                    Image(.entzuendlich)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-flamme.svg")
                        .font(.caption)
                }
                HStack{
                    Image(.gasflasche)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-bottle.svg")
                        .font(.caption)
                }
                HStack{
                    Image(.gesundheitsschaedlich)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-silhouette.svg")
                        .font(.caption)
                }
                HStack{
                    Image(.reizend)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-exclam.svg")
                        .font(.caption)
                }
                HStack{
                    Image(.giftig)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-skull.svg")
                        .font(.caption)
                }
                HStack{
                    Image(.umweltschaedlich)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-pollu.svg")
                        .font(.caption)
                }
            }
            Section("Infoquellen"){
                Text("https://pubchem.ncbi.nlm.nih.gov/periodic-table")
                Text("Wikipedia (alle Artikel zu den chemischen Elementen)")
            }
        }.navigationTitle("Credits")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

//
//  Willkommen.swift
//  Neodym
//
//  Created by Max Eckstein on 08.06.23.
//

import SwiftUI

struct Willkommen: View {
    
    var benutzer: Benutzer
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(spacing: 2){
                    Text("Willkommen bei")
                    HStack { Spacer() }
                    Text("Neodym")
                        .foregroundColor(.indigo)
                }
                .padding(.top)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                Spacer()
                GeometryReader { geo in
                    ZStack {
                        Image(.logo)
                            .resizable()
                            .frame(width: geo.size.width / 1.7, height: geo.size.width / 1.7)
                            .mask {
                                RoundedRectangle(cornerRadius: 25)
                                    .strokeBorder(lineWidth: 4)
                            }
                        Image(.logo)
                            .resizable()
                            .frame(width: geo.size.width / 2, height: geo.size.width / 2)
                            .cornerRadius(20)
                    }.offset(x: (geo.size.width - (geo.size.width / 1.7)) / 2, y: (geo.size.width - (geo.size.width / 1.7)) / 2)
                }.aspectRatio(1, contentMode: .fit)
                
                Spacer()
                
                VStack(spacing: 15){
                    NavigationLink(destination: Anmeldung(anmeldeArt: .schule, benutzer: benutzer)) {
                        anmeldeButton("Über Schule anmelden", bildName: "Schule")
                    }
                    Divider()
                        .background(.pink)
                        .padding(.horizontal, 20)
                    NavigationLink(destination: Anmeldung(anmeldeArt: .anmelden, benutzer: benutzer)) {
                        anmeldeButton("Normal anmelden", bildName: "Mann")
                    }
                    NavigationLink(destination: Anmeldung(anmeldeArt: .registrieren, benutzer: benutzer)) {
                        anmeldeButton("Neu registrieren", bildName: "Frau")
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            .frame(maxWidth: 700)}
    }
    
    func anmeldeButton(_ titel: String, bildName: String) -> some View {
        return HStack{
            Image(bildName)
                .resizable()
                .frame(width: 35, height:35)
            Spacer()
            Text(titel)
                .foregroundColor(.black)
                .font(.title3)
            Spacer()
        }.padding(.horizontal)
            .frame(height: 60)
            .background(.white)
            .cornerRadius(15)
            .shadow(radius: 7)
    }
}

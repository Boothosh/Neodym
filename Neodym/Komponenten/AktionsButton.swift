//
//  AktionsButton.swift
//  Neodym
//
//  Created by Max Eckstein on 18.12.23.
//

import SwiftUI

struct AktionsButton: View {
    
    let titel: String
    let bild: String?
    let position: Position
    
    init(titel: String, bild: String? = nil, position: Position = .links) {
        self.titel = titel
        self.bild = bild
        self.position = position
    }
    
    var body: some View {
        return HStack{
            if let bild, position == .links {
                Image(bild)
                    .resizable()
                    .frame(width: 35, height:35)
            }
            Spacer()
            Text(titel)
                .foregroundColor(.black)
                .minimumScaleFactor(0.01)
                .lineLimit(5)
                .font(.title3)
            Spacer()
            if let bild, position == .rechts {
                Image(bild)
                    .resizable()
                    .frame(width: 35, height:35)
            }
        }.padding(.horizontal)
            .frame(height: 60)
            .background(.white)
            .cornerRadius(15)
            .shadow(radius: 7)
    }
    
    enum Position {
        case links, rechts
    }
}

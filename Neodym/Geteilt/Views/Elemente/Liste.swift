//
//  Liste.swift
//  Neodym
//
//  Created by Max Eckstein on 05.06.23.
//

import SwiftUI

struct Liste: View {
    
    let elemente: [Element]
    @Binding var suchBegriff: String
    @State var ausgewaeltesElement: Element? = nil
    
    var body: some View {
        GeometryReader { geo in
            List {
                ForEach(elemente.filter({ element in
                    element.name.lowercased().contains(suchBegriff.lowercased()) || element.symbol.lowercased().contains(suchBegriff.lowercased()) || suchBegriff == ""
                })) { element in
                    NavigationLink(destination: ElementDetail(element: element)){
                        HStack{
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
                    }
                }
            }
        }
    }
}

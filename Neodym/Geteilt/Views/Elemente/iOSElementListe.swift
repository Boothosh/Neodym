//
//  iOSElementListe.swift
//  Neodym
//
//  Created by Max Eckstein on 23.11.23.
//

import SwiftUI

struct iOSElementListe: View {
    @Binding var elementeManager: ElementManager
    @State var suchBegriff = ""
    
    var elementListe: [Element] {
        elementeManager.alleElemente.filter({ element in
            element.name.lowercased().contains(suchBegriff.lowercased()) || element.symbol.lowercased().contains(suchBegriff.lowercased()) || suchBegriff == ""
        })
    }
    
    var body: some View {
        List(elementListe){ element in
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
                            .foregroundStyle(Color(uiColor: UIColor.label))
                        Text(element.klassifikation)
                            .fontWeight(.bold)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }.navigationTitle("Elemente")
            .searchable(text: $suchBegriff)
    }
}

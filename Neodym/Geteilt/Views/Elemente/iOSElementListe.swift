//
//  iOSElementListe.swift
//  Neodym
//
//  Created by Max Eckstein on 23.11.23.
//

import SwiftUI

struct iOSElementListe: View {
    
    @Environment(Elemente.self) private var elemente
    @Binding var navigationPfad: NavigationPath
    
    @Binding var suchBegriff: String
    @Binding var suche: Bool
    @AppStorage("sortiertNach") private var sortiertNach = "Ordnungszahl"
    @AppStorage("sortiertAufsteigend") private var sortiertAufsteigend = true
    
    //@State private var zeigePeriodenSystem = false
    
    @MainActor var elementListe: [Element] {
        elemente.alleElemente.filter({ element in
            element.name.lowercased().contains(suchBegriff.lowercased()) || element.symbol.lowercased().contains(suchBegriff.lowercased()) || suchBegriff == ""
        }).sorted {
            switch sortiertNach {
                case "Ordnungszahl":
                    return sortiertAufsteigend ? $0.kernladungszahl < $1.kernladungszahl : $0.kernladungszahl > $1.kernladungszahl
                case "Atomradius":
                    let r0 = $0.radius ?? 10000
                    let r1 = $1.radius ?? 10000
                    return sortiertAufsteigend ? r0 < r1 : r0 > r1
                case "Entdeckungsjahr":
                    return sortiertAufsteigend ? $0.entdeckt < $1.entdeckt : $0.entdeckt > $1.entdeckt
                case "Name":
                    return sortiertAufsteigend ? $0.name < $1.name : $0.name > $1.name
                default:
                    return false
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPfad) {
            List(elementListe){ element in
                NavigationLink(value: element){
                    HStack{
                        Text(element.symbol)
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.bold)
                            .shadow(radius: 5)
                            .frame(width: 60, height: 60)
                            .background(Color(element.klassifikation))
                            .cornerRadius(5)
                            .overlay(alignment: .bottomTrailing){
                                Text(element.kernladungszahl.description)
                                    .foregroundStyle(.white)
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(3)
                                    .padding(.trailing, 2)
                            }
                            .shadow(radius: 5)
                            .padding(.trailing)
                        VStack(alignment: .leading){
                            Text(element.name)
                                .font(.title3)
                                .foregroundStyle(Color(uiColor: UIColor.label))
                            let text = (sortiertNach == "Atomradius") ? "Atomradius: \(element.radius != nil ? element.radius!.description + " pm" : "Unbekannt")" : (sortiertNach == "Entdeckungsjahr") ? "Entdeckungsjahr: \(element.entdeckt == -1 ? "Antik" : element.entdeckt.description)" : element.klassifikation
                            Text(text)
                                .fontWeight(.bold)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }.animation(.easeIn, value: elementListe)
            .navigationTitle("Elemente")
            .searchable(text: $suchBegriff, isPresented: $suche)
            .navigationDestination(for: Element.self) { element in
                ElementDetail(element: element)
            }
            .toolbar {
                Menu("Sortierung", systemImage: "line.3.horizontal.decrease") {
                    Picker(selection: $sortiertNach) {
                        Text("Ordnungszahl")
                            .tag("Ordnungszahl")
                        Text("Atomradius")
                            .tag("Atomradius")
                        Text("Entdeckungsjahr")
                            .tag("Entdeckungsjahr")
                        Text("Name")
                            .tag("Name")
                    } label: {
                        
                    }
                    Divider()
                    Picker(selection: $sortiertAufsteigend) {
                        Text("Aufsteigend")
                            .tag(true)
                        Text("Absteigend")
                            .tag(false)
                    } label: {
                        
                    }
                }
//                Button {
//                    zeigePeriodenSystem = true
//                } label: {
//                    Label("PSE", systemImage: "square.grid.4x3.fill")
//                }
            }
//            .fullScreenCover(isPresented: $zeigePeriodenSystem) {
//                NavigationStack {
//                    Periodensystem()
//                      .enviroment(elemente)
//                }
//            }
        }
    }
}

//
//  System.swift
//  Neodym
//
//  Created by Max Eckstein on 05.06.23.
//

import SwiftUI

struct System: View {
    
    @Binding var elementManager: ElementManager
    let gruppenNamen: [Int: String] = [
        1: ("I"),
        2: ("II"),
        13: ("III"),
        14: ("IV"),
        15: ("V"),
        16: ("VI"),
        17: ("VII"),
        18: ("VIII"),
    ]
    
    @Binding var suchBegriff: String
    @State var ausgewaeltesElement: Element? = nil
    
    @State var zeigeLanthanoide = false
    @State var zeigeActinoide = false
    
    
    var body: some View {
        GeometryReader { geoD in
            ScrollView {
                let breite: CGFloat = (geoD.size.width - 18*1 - 5 - 20)/19
                VStack(spacing: 1){
                    // Normales Periodensystem
                    HStack(spacing: 1){
                        ForEach(1..<19) { i in
                            VStack(alignment: .center){
                                if let gruppenName = gruppenNamen[i] {
                                    Text(gruppenName)
                                        .font(.system(size: 18, weight: .black))
                                } else {
                                    Text(i.description)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.secondary)
                            .frame(width: breite, height: breite * 1.1)
                        }
                    }.padding(.leading, breite + 1)
                    ForEach(elementManager.perioden) { periode in
                        HStack(spacing: 1){
                            Text(periode.nummer)
                                .font(.system(size: 18, weight: .black))
                                .frame(width: breite)
                                .foregroundColor(.secondary)
                            ForEach(periode.elemente) { element in
                                switch element.name {
                                    case "Platzhalter":
                                        Spacer()
                                    case "Lanthan-Button":
                                        Image(systemName: "ellipsis.curlybraces")
                                            .frame(width: breite, height: breite * 1.1)
                                            .background(.gray)
                                            .foregroundColor(.white)
                                            .onTapGesture {
                                                zeigeLanthanoide.toggle()
                                            }
                                    case "Actinium-Button":
                                        Image(systemName: "ellipsis.curlybraces")
                                            .frame(width: breite, height: breite * 1.1)
                                            .background(.gray)
                                            .foregroundColor(.white)
                                            .onTapGesture {
                                                zeigeActinoide.toggle()
                                            }
                                    default:
                                        let ausgegraut = suchBegriff != "" && !element.name.lowercased().contains(suchBegriff.lowercased()) && !element.symbol.lowercased().contains(suchBegriff.lowercased())
                                        ElementKarte(element: element, breite: breite, ausgegraut: ausgegraut)
                                            .onTapGesture {
                                                if !ausgegraut {
                                                    ausgewaeltesElement = element
                                                }
                                            }
                                }
                            }
                        }
                    }
                    if zeigeActinoide || zeigeLanthanoide {
                        Spacer().frame(height: 8)
                    }
                    if zeigeLanthanoide {
                        HStack(spacing: 1){
                            Text("Lanthanoide")
                                .font(.caption)
                                .frame(width: breite*2 + 1)
                            ForEach(elementManager.lanthanoide) { element in
                                let ausgegraut = suchBegriff != "" && !element.name.lowercased().contains(suchBegriff.lowercased()) && !element.symbol.lowercased().contains(suchBegriff.lowercased())
                                ElementKarte(element: element, breite: breite, ausgegraut: ausgegraut)
                                    .onTapGesture {
                                        if !ausgegraut {
                                            ausgewaeltesElement = element
                                        }
                                    }
                            }
                        }
                    }
                    if zeigeActinoide {
                        HStack(spacing: 1){
                            Text("Actinoide")
                                .font(.caption)
                                .frame(width: breite*2 + 1)
                            ForEach(elementManager.actinoide) { element in
                                let ausgegraut = suchBegriff != "" && !element.name.lowercased().contains(suchBegriff.lowercased()) && !element.symbol.lowercased().contains(suchBegriff.lowercased())
                                ElementKarte(element: element, breite: breite, ausgegraut: ausgegraut)
                                    .onTapGesture {
                                        if !ausgegraut {
                                            ausgewaeltesElement = element
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding(.leading, 5)
                .padding(.trailing, 20)
                .sheet(item: $ausgewaeltesElement) { element in
                    NavigationStack {
                        ElementDetail(element: element)
                            .toolbar {
                                ToolbarItem {
                                    Button {
                                        ausgewaeltesElement = nil
                                    } label: {
                                        Text("Schließen")
                                    }
                                    .keyboardShortcut(.cancelAction)
                                }
                            }
                    }
                }
            }.onAppear {
                print(geoD)
            }
        }
            .onChange(of: suchBegriff) { _ in
                zeigeLanthanoide = true
                zeigeActinoide = true
            }
    }
    
    private struct ElementKarte: View, Equatable {
        
        static func == (lhs: ElementKarte, rhs: ElementKarte) -> Bool {
            return lhs.breite == rhs.breite && lhs.ausgegraut == rhs.ausgegraut
        }
        
        let element: Element
        let breite: Double
        let ausgegraut: Bool
        
        var body: some View {
            return Text(element.symbol)
                .font(.system(size: 18, weight: .black))
                .shadow(radius: 5)
                .frame(width: breite - 10, height: breite * 1.1 - 10)
                .overlay(breite > 55 ? Text(element.name)
                    .font(.system(size: 8))
                    .lineLimit(1) : nil, alignment: .bottom)
                .overlay(breite > 55 ? Text(element.kernladungszahl.description)
                    .font(.system(size: 9)) : nil, alignment: .topLeading)
                .overlay(breite > 55 ? Text("\(element.atommasse, specifier: "%.2f")")
                    .font(.system(size: 9)) : nil, alignment: .topTrailing)
                .padding(5)
                .frame(width: breite, height: breite * 1.1)
                .background(ausgegraut ? .gray : Color(element.klassifikation))
                .foregroundColor(.white.opacity(ausgegraut ? 0.5 : 1))
                .animation(.easeInOut(duration: 0.1), value: ausgegraut)
        }
    }
}

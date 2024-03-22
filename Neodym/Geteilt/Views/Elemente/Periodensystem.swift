//
//  Periodensystem.swift
//  Neodym
//
//  Created by Max Eckstein on 05.01.24.
//

//import SwiftUI
//
//struct Periodensystem: View {
//    
//    let kleinerScreen = true
//    var elementManager: ElementManager
//    
//    @State private var nebengruppenZeigen = false
//    @State private var lanthanUndActanZeigen = false
//    @State private var zustandAnzeigenBeiTemp = false
//    @State private var temperatur = Temperatur.standard
//    
//    var body: some View {
//        GeometryReader { geo in
//            
//            
//            let elementBreite = (geo.size.width - (sichtbareElementeProPeriode-1)*2) / sichtbareElementeProPeriode
//            
//            ForEach(elementManager.alleElemente) { element in
//                
//                let offset = CGFloat((element.gruppe - 1)) * (elementBreite + 2)
//                
//                Color.blue
//                    .frame(width: 50, height: 50)
//                    .position(x: offset, y: offset)
//            }
//        }.coordinateSpace(name: "PSE")
//        .navigationTitle("Elemente")
//        .navigationBarTitleDisplayMode(kleinerScreen ? .inline : .large)
//    }
//    
//    var sichtbareElementeProPeriode: CGFloat {
//        if !lanthanUndActanZeigen {
//            if !nebengruppenZeigen {
//                return 8
//            } else {
//                return 18
//            }
//        } else {
//            return 32
//        }
//    }
//}

//
//  PESystem.swift
//  Neodym
//
//  Created by Max Eckstein on 05.06.23.
//

import SwiftUI

struct ElementeBetrachter: View {
    
    @Binding var elementeManager: ElementManager
    @State var systemAnsicht = UIDevice.current.userInterfaceIdiom != .phone
    @State var suchBegriff: String = ""
    
    var body: some View {
        VStack(alignment: .center){
            if elementeManager.perioden.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if systemAnsicht {
                System(elementManager: $elementeManager, suchBegriff: $suchBegriff)
            } else {
                Liste(elemente: elementeManager.alleElemente, suchBegriff: $suchBegriff)
            }
        }
        .searchable(text: $suchBegriff, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Elemente")
            .toolbar {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    ToolbarItem {
                        Picker("Ansicht", selection: $systemAnsicht) {
                            Text("Periodensystem").tag(true)
                            Text("Liste").tag(false)
                        }.pickerStyle(.segmented)
                    }
                }
            }
    }
}

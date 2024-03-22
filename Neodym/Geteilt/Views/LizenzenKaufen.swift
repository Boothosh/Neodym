//
//  LizenzenKaufen.swift
//  Neodym
//
//  Created by Max Eckstein on 28.02.24.
//

import SwiftUI
import StoreKit

struct LizenzenKaufen: View {
    
    @Environment(NeoStore.self) private var store
    
    @State var lizenzen: [Lizenz] = []
    @State var zeigeSheet = false
    @State var anzahl = 0
    
    var body: some View {
        List {
            if !lizenzen.isEmpty {
                ForEach(lizenzen) { lizenz in
                    
                }
            } else {
                ContentUnavailableView(label: {
                    Label("Keine Lizenzen", systemImage: "key.slash")
                }, description: {
                    Text("Sie besitzen noch keine Lizenzen. Kaufen Sie Lizenzen, um diese hier verwalten zu können.")
                }, actions: {
                    Button(action: {
                        zeigeSheet = true
                    }, label: {
                        Text("Lizenzen kaufen wird in Kürze verfügbar sein!")
                    }).disabled(true)
                })
            }
        }.navigationTitle("Lizenzen")
        .sheet(isPresented: $zeigeSheet, content: {
            NavigationStack {
                Form {
                    if let lz = store.lizenz {
                        Section(header: Text("Wieviele Lizenzen möchten Sie kaufen?")){
                            HStack {
                                TextField("Anzahl der Lizenzen", value: $anzahl, format: .number)
                                Stepper(value: $anzahl, label: {})
                            }
                        }
                        Section(header: Text("Preisvorschau")){
                            HStack {
                                Text("Preis pro Lizenz:")
                                Spacer()
                                Text(lz.displayPrice)
                            }
                            HStack {
                                Text("Preis für \(anzahl) Lizenzen:")
                                Spacer()
                                Text(formattedPreis())
                            }
                        }
                        Section(header: Text("Kaufen")){
                            Button {
                                Task {
                                    do {
                                        try await NeoFire.kaufeTestLizenzen()
                                    } catch {
                                        
                                    }
                                }
                            } label: {
                                Text("30 30-Tage Lizenzen kaufen (kostenlos)")
                            }
                            Button {
                                Task {
                                    do {
                                        if try await store.kauf(lz, anzahl) {
                                            try await NeoFire.kaufeLizenzen(anzahl)
                                        }
                                    } catch {
                                        
                                    }
                                }
                            } label: {
                                Text("Kaufen")
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }.navigationTitle("Lizenzen kaufen")
                .navigationBarTitleDisplayMode(.large)
            }
        })
    }
    
    func formattedPreis() -> String {
        guard let lz = store.lizenz else { return "" }
        do {
            let r = try Regex("[0-9]+[.,]*[0-9]*")
            let preis = Decimal(anzahl)*lz.price
            return lz.displayPrice.replacing(r, with: "\(preis)")
        } catch {
            return ""
        }
    }
}

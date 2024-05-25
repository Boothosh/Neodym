//
//  LizenzenKaufen.swift
//  Neodym
//
//  Created by Max Eckstein on 28.02.24.
//

import SwiftUI
import StoreKit

struct LizenzenUebersicht: View {
    
    @Environment(NeoStore.self) private var store
    @Environment(NeoAuth.self) private var auth
    @Environment(\.horizontalSizeClass) private var hSC
    
    @State private var zeigeSheet = false
    @State private var ladeNeu = false
    @State private var anzahl = 0
    
    var body: some View {
        VStack {
            if !auth.lizenzen.isEmpty {
                if hSC != .compact {
                    Table(auth.lizenzen) {
                        TableColumn("Schlüssel") { lz in
                            Text(lz.schluessel)
                                .textSelection(.enabled)
                        }
                        TableColumn("Aktiv") { lz in
                            Circle().fill(lz.aktiv ? .green : .yellow)
                                .frame(width: 15, height: 15)
                        }.width(50)
                        TableColumn("Benutzer-ID") { lz in
                            if let id = lz.benutzerID {
                                Text(id)
                            } else {
                                Text("Kein Benutzer")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        TableColumn("Enddatum") { lz in
                            if let ende = lz.ablaufdatum {
                                Text(ende.formatted())
                            } else {
                                Text("Unbegrenzt")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    List(auth.lizenzen) { lz in
                        NavigationLink {
                            Form {
                                Section("Informationen") {
                                    Text("Schlüssel: \(lz.schluessel)")
                                        .textSelection(.enabled)
                                    Text("Aktiv: \(lz.aktiv ? "Ja" : "Nein")")
                                    if let id = lz.benutzerID {
                                        Text("Benutzer: \(id)")
                                    }
                                    if let ablaufdatum = lz.ablaufdatum {
                                        Text("Ablaufdatum: \(ablaufdatum.formatted())")
                                    }
                                }
                            }
                            .formStyle(.grouped)
                            .navigationTitle("Lizenz-Info")
                        } label: {
                            HStack {
                                if lz.aktiv {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                }
                                Text(lz.schluessel)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(label: {
                    Label("Keine Lizenzen", systemImage: "key.slash")
                }, description: {
                    Text("Sie besitzen noch keine Lizenzen. Kaufen Sie Lizenzen, um diese hier verwalten zu können.")
                        .frame(maxWidth: 400)
                }, actions: {
                    Button(action: {
                        zeigeSheet = true
                    }, label: {
                        Text("Lizenzen kaufen!")
                    })
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .cornerRadius(10)
                })
            }
        }.navigationTitle("Lizenzen")
            .toolbar {
                if !auth.lizenzen.isEmpty {
                    ToolbarItem {
                        Button {
                            zeigeSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.white, .blue)
                        }
                    }
                    ToolbarItem {
                        Button {
                            ladeNeu = true
                            Task {
                                do {
                                    try await auth.ladeLizenzen()
                                } catch {}
                                ladeNeu = false
                            }
                        } label: {
                            if !ladeNeu {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundStyle(.blue)
                            } else {
                                ProgressView()
                            }
                        }
                    }
                }
            }
        .sheet(isPresented: $zeigeSheet, content: {
            LizenzenKaufen()
                .environment(store)
        })
    }
}

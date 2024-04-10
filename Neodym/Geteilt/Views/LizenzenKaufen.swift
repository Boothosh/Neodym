//
//  LizenzenKaufen.swift
//  Neodym
//
//  Created by Max Eckstein on 02.04.24.
//

import SwiftUI
import StoreKit

struct LizenzenKaufen: View {
    
    @Environment(NeoStore.self)     var store
    @Environment(NeoAuth.self)      var auth
    @Environment(\.dismiss)         var schliessen
    
    @State private var anzahl = 1
    @State private var auswahl: Product? = nil
    @State private var bounceCounter: [Product: Int] = [:]
    @State private var buttonMussLaden = false
    @State private var zeigeInfoSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let lz = store.lizenzen {
                    VStack(alignment: .leading, spacing: 10){
                        Button {
                            zeigeInfoSheet = true
                        } label: {
                            Text("\(Image(systemName: "info.circle")) Wie funktionieren Lizenzen?")
                        }
                        Text("Für den Lizenzkauf gibt es die folgenden Packete:")
                        ForEach(lz){ produkt in
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading){
                                        Text(produkt.displayName)
                                            .font(.headline)
                                        Text("\(produkt.displayPrice)")
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    Image(systemName: auswahl == produkt ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(auswahl == produkt ? .white : .gray, .blue)
                                        .font(.title2)
                                        .symbolEffect(.bounce, value: bounceCounter[produkt] ?? 0)
                                }
                                Divider()
                                Text(produkt.description)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .onTapGesture {
                                auswahl = produkt
                                bounceCounter[auswahl!] = 1 + (bounceCounter[auswahl!] ?? 0)
                            }
                            .overlay(auswahl == produkt ? RoundedRectangle(cornerRadius: 15).stroke(lineWidth: 2).fill(.blue) : nil)
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    .sensoryFeedback(.selection, trigger: auswahl)
                    .task {
                        withAnimation {
                            auswahl = lz[1]
                            bounceCounter[auswahl!] = 1
                        }
                    }
                    VStack(spacing: 20){
                        HStack {
                            Button {
                                anzahl -= 1
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundStyle(.white, anzahl >= 10 ? .gray : .blue)
                            }.disabled(anzahl <= 1)
                            VStack {
                                Text("Anzahl")
                                    .font(.caption2)
                                Text("\(anzahl)")
                            }
                            Button {
                                anzahl += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundStyle(.white, anzahl >= 10 ? .gray : .blue)
                            }.disabled(anzahl >= 10)
                        }
                        Button{
                            Task {
                                guard let auswahl else { return }
                                do {
                                    buttonMussLaden = true
                                    if try await store.kauf(auswahl, anzahl: anzahl) {
                                        try await auth.ladeLizenzen()
                                        schliessen()
                                    }
                                } catch {
                                    
                                }
                                buttonMussLaden = false
                            }
                        } label: {
                            Group {
                                if !buttonMussLaden {
                                    VStack {
                                        Text("Kaufen")
                                            .font(.title3)
                                            .bold()
                                    }
                                } else {
                                    ProgressView()
                                }
                            }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        .keyboardShortcut(.defaultAction)
                        HStack {
                            Link(destination: URL(string: "https://neodym.app/rechtliches#datenschutz")!) {
                                Text("Datenschutz")
                            }
                            Image(systemName: "circle")
                                .font(.caption2)
                            Link(destination: URL(string: "https://neodym.app/rechtliches#agb")!) {
                                Text("AGB")
                            }
                        }.font(.caption)
                        .bold()
                    }.padding()
                    .frame(maxWidth: 600)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Lizenzen kaufen")
            .sheet(isPresented: $zeigeInfoSheet, content: {
                InfoSheet("Lizenzen", .lizenzen)
            })
        }
    }
}

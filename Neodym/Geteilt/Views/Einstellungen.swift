//
//  Einstellungen.swift
//  Neodym
//
//  Created by Max Eckstein on 13.06.23.
//

import SwiftUI

struct Einstellungen: View {
    
    @Environment(NeoAuth.self) private var auth
    @Environment(Elemente.self) private var elemente
    @Environment(NeoStore.self) private var store
    @Environment(\.dismiss) private var schliessen
            
    @State private var zeigeAlert = false
    @State private var titel = ""
    @State private var nachricht = ""
    
    @AppStorage("temperaturFormat") var temperaturFormat = "kelvin"
    
    @State private var zeigeBearbeiteAbonnement = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Neodym")
                            .foregroundStyle(.linearGradient(colors: [.green, .blue, .indigo,], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.white, .green)
                            .frame(width: 30, height: 30)
                    }.font(.largeTitle)
                    Text("Kostenlose Vollversion")
                }
//                Section {
//                    HStack {
//                        if auth.angemeldet == true {
//                            if auth.email != nil {
//                                Image("lehrer")
//                                    .foregroundStyle(.primary, .green, .teal)
//                            } else {
//                                Image(systemName: "graduationcap.fill")
//                                    .foregroundStyle(.green)
//                            }
//                        }
//                        Text(store.hatBerechtigung == true ? "Neodym +" : auth.email != nil ? "Lehrer:in" : " Schüler:in")
//                            .foregroundStyle(.linearGradient(colors: [.green, .blue, .indigo,], startPoint: .topLeading, endPoint: .bottomTrailing))
//                        Spacer()
//                        Image(systemName: store.hatBerechtigung == true ? "crown.fill" : "checkmark.seal.fill")
//                            .foregroundStyle(store.hatBerechtigung == true ? .yellow :
//                                    .white, .green)
//                            .frame(width: 30, height: 30)
//                    }.font(.largeTitle)
//                    if store.hatAbo {
//                        Button {
//                            zeigeBearbeiteAbonnement = true
//                        } label: {
//                            Label {
//                                Text("Abonnement bearbeiten")
//                            } icon: {
//                                Image(systemName: "creditcard")
//                                    .foregroundStyle(.indigo)
//                            }
//                        }.foregroundStyle(.prim)
//                    } else if store.hatBerechtigung == true {
//                        Text("Vollversion lebenslang")
//                    } else if let email = auth.email {
//                        Text("E-Mail: \(email)")
//                    } else if let lizenz = auth.lizenzSchluessel, let ablaufdatum = auth.lizenzEndDatum {
//                        Text("Lizenz: \(lizenz)")
//                        Text("Ablaufdatum: \(ablaufdatum.formatted())")
//                    }
//                }
                Section {
                    NavigationLink {
                        Form {
                            Section("Einheiten"){
                                Picker("Temperatur", selection: $temperaturFormat) {
                                    Text("Kelvin").tag("kelvin")
                                    Text("Celsius").tag("celsius")
                                    Text("Fahrenheit").tag("fahrenheit")
                                }
                            }
                        }.navigationTitle("Darstellung")
                            .formStyle(.grouped)
                        #if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                    } label: {
                        Label("Darstellung", systemImage: "sparkles")
                    }
                    NavigationLink {
                        Form {
                            Section {
                                if elemente.spotlightEintraegeVorhanden {
                                    LabelButton(text: "Alle Spotlight-Sucheinträge löschen", symbol: "trash.fill", action: {
                                        await elemente.loescheSpotlightEintraege()
                                    }, role: .destructive)
                                } else {
                                    LabelButton(text: "Spotlight-Sucheinträge wiederherstellen", symbol: "arrow.uturn.backward", action: {
                                        await elemente.indexeFuerSpotlight()
                                    })
                                }
                            } header: {
                                Text("Spotlight-Suche")
                            } footer: {
                                Text("Alle Einträge aus der Spotlight-Suche werden entfernt. Diese Aktion") +
                                Text(" kann ").bold() +
                                Text("rückgängig gemacht werden")
                            }
                        }.navigationTitle("Speicher")
                            .formStyle(.grouped)
                        #if os(iOS) || os(visionOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                    } label: {
                        Label("Speicher", systemImage: "server.rack")
                    }
                }
                Section {
                    NavigationLink {
                        Credits()
                    } label: {
                        Label("Credits", systemImage: "heart.circle")
                    }
                    DisclosureGroup("Rechtliches") {
                        link("AGB", bild: "scroll", ziel: "https://neodym.app/rechtliches#agb")
                        link("Datenschutz", bild: "lock.shield", ziel: "https://neodym.app/rechtliches#datenschutz")
                        link("Impressum", bild: "person.text.rectangle", ziel: "https://neodym.app/rechtliches#impressum")
                    }
                }
//                if auth.verifiziert == true {
//                    Section {
//                        if auth.email != nil {
//                            LabelButton(text: "Abmelden", symbol: "rectangle.portrait.and.arrow.forward", action: {
//                                do {
//                                    try await auth.abmelden()
//                                    schliessen()
//                                } catch {
//                                    titel = "Abmeldevorgang fehlgeschlagen"
//                                    nachricht = error.localizedDescription
//                                    zeigeAlert = true
//                                }
//                            }, role: .destructive)
//                        }
//                        LabelButton(text: "Abmelden und Konto löschen", symbol: "trash.fill", action: {
//                            do {
//                                try await auth.abmelden(loeschen: true)
//                            } catch {
//                                titel = "Abmeldevorgang fehlgeschlagen"
//                                nachricht = error.localizedDescription
//                                zeigeAlert = true
//                                schliessen()
//                            }
//                        }, role: .destructive)
//                    }
//                }
                Section {
                    link("Feedback", bild: "bubble.left.and.exclamationmark.bubble.right", ziel: "https://apps.apple.com/app/id6466750604?action=write-review")
                    link("Website", bild: "globe", ziel: "https://neodym.app")
                    link("Instagram", bild: "insta", ziel: "https://instagram.com/neodym_app")
                } footer: {
                    VStack(alignment: .leading, spacing: 0) {
                        if store.hatBerechtigung != true {
                            Text("Benutzer ID: \(auth.id ?? "Fehler")")
                        }
                        Text("Version: 1.3")
                        Text("© 2024 Bromedia GbR")
                        HStack {
                            Spacer()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Einstellungen")
            .alert(titel, isPresented: $zeigeAlert, actions: {
                Button {
                    zeigeAlert = false
                } label: {
                    Text("Okay")
                }
            }, message: {Text(nachricht)})
            #if os(iOS) || os(visionOS)
            .listStyle(.insetGrouped)
//            .manageSubscriptionsSheet(
//                isPresented: $zeigeBearbeiteAbonnement,
//                subscriptionGroupID: "21424638"
//            )
            #endif
        }
    }
    
    @ViewBuilder
    func link(_ text: String, bild: String, ziel: String) -> some View {
        if let url = URL(string: ziel) {
            Link(destination: url) {
                HStack {
                    Label {
                        Text(text)
                            .foregroundStyle(.prim)
                    } icon: {
                        if bild == "insta" {
                            Image("insta")
                                .resizable()
                                .frame(width: 30, height: 30)
                        } else {
                            Image(systemName: bild)
                        }
                    }
                    Spacer()
                    Image(systemName: "link")
                }
            }
        }
    }
}

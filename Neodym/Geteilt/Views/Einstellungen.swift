//
//  Einstellungen.swift
//  Neodym
//
//  Created by Max Eckstein on 13.06.23.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import PhotosUI

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
            List {
                Section {
                    HStack {
                        if auth.angemeldet == true {
                            Image((auth.email != nil) ? "lehrer" : "schueler")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Text(store.hatBerechtigung == true ? "Neodym +" : auth.email != nil ? "Lehrer:in" : " Schüler:in")
                            .font(.largeTitle)
                            .foregroundStyle(.linearGradient(colors: [.green, .blue, .indigo,], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Spacer()
                        Image(systemName: store.hatBerechtigung == true ? "crown.fill" : "checkmark.seal.fill")
                            .foregroundStyle(store.hatBerechtigung == true ? .yellow :
                                    .white, .green)
                            .font(.largeTitle)
                            .frame(width: 30, height: 30)
                    }
                    if store.hatAbo {
                        Button {
                            zeigeBearbeiteAbonnement = true
                        } label: {
                            FTLabel("Abonnement bearbeiten", bild: "abo")
                        }.foregroundStyle(.prim)
                    } else if store.hatBerechtigung == true {
                        Text("Vollversion lebenslang")
                    } else if let email = auth.email {
                        Text("E-Mail: \(email)")
                    } else if let lizenz = auth.lizenzSchluessel, let ablaufdatum = auth.lizenzEndDatum {
                        Text("Lizenz: \(lizenz)")
                        Text("Ablaufdatum: \(ablaufdatum.formatted())")
                    }
                }
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
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        FTLabel("Darstellung", bild: "darstellung")
                    }
                    NavigationLink {
                        Form {
                            Section {
                                if elemente.spotlightEintraegeVorhanden {
                                    LabelButton(text: "Alle Spotlight-Sucheinträge löschen", symbol: "loeschen", action: {
                                        await elemente.loescheSpotlightEintraege()
                                    }, role: .destructive)
                                } else {
                                    LabelButton(text: "Spotlight-Sucheinträge wiederherstellen", symbol: "zurueck", action: {
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
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        FTLabel("Speicher", bild: "speicher")
                    }
                }
                Section {
                    NavigationLink {
                        Credits()
                    } label: {
                        FTLabel("Credits", bild: "credits")
                    }
                    DisclosureGroup("Rechtliches") {
                        link("AGB", bild: "agb", ziel: "https://neodym.app/rechtliches#agb")
                        link("Datenschutz", bild: "datenschutz", ziel: "https://neodym.app/rechtliches#datenschutz")
                        link("Impressum", bild: "impressum", ziel: "https://neodym.app/rechtliches#impressum")
                    }
                }
                if auth.verifiziert == true {
                    Section {
                        if auth.email != nil {
                            LabelButton(text: "Abmelden", symbol: "abmelden", action: {
                                do {
                                    try await auth.abmelden()
                                    schliessen()
                                } catch {
                                    titel = "Abmeldevorgang fehlgeschlagen"
                                    nachricht = error.localizedDescription
                                    zeigeAlert = true
                                }
                            }, role: .destructive)
                        }
                        LabelButton(text: "Abmelden und Konto löschen", symbol: "loeschen", action: {
                            do {
                                try await auth.abmelden(loeschen: true)
                            } catch {
                                titel = "Abmeldevorgang fehlgeschlagen"
                                nachricht = error.localizedDescription
                                zeigeAlert = true
                                schliessen()
                            }
                        }, role: .destructive)
                    }
                }
                Section {
                    link("Feedback", bild: "feedback", ziel: "https://apps.apple.com/app/id6466750604?action=write-review")
                    link("Website", bild: "website", ziel: "https://neodym.app")
                    link("Instagram", bild: "insta", ziel: "https://instagram.com/neodym_app")
                } footer: {
                    VStack(alignment: .leading) {
                        if store.hatBerechtigung != true {
                            Text("Benutzer ID: \(auth.id ?? "Fehler")")
                        }
                        Text("Version: 1.2")
                        Text("© 2024 Bromedia GbR")
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .listStyle(.insetGrouped)
            .alert(titel, isPresented: $zeigeAlert, actions: {
                Button {
                    zeigeAlert = false
                } label: {
                    Text("Okay")
                }
            }, message: {Text(nachricht)})
            .manageSubscriptionsSheet(
                isPresented: $zeigeBearbeiteAbonnement,
                subscriptionGroupID: "21424638"
            )
        }
    }
    
    @ViewBuilder
    func link(_ text: String, bild: String, ziel: String) -> some View {
        if let url = URL(string: ziel) {
            Link(destination: url) {
                HStack {
                    FTLabel(text, bild: bild)
                        .foregroundStyle(.prim)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
            }
        }
    }
}

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
                        Text(store.hatBerechtigung == true ? "Neodym+" : auth.email != nil ? "🧑🏼‍🏫 Lehrer*in" : "🧑🏼‍🎓 Schüler*in")
                            .font(.largeTitle)
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
                            Label(title: { Text("Abonnement bearbeiten").foregroundStyle(Color(uiColor: UIColor.label))},
                                  icon: { Image(systemName: "creditcard") })
                        }
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
                    link(link: "https://neodym.app/rechtliches#agb", text: "ABG", systemImage: "scroll")
                    link(link: "https://neodym.app/rechtliches#datenschutz", text: "Datenschutz", systemImage: "lock.shield")
                    link(link: "https://neodym.app/rechtliches#impressum", text: "Impressum", systemImage: "person")
                    NavigationLink {
                        Credits()
                    } label: {
                        Label("Credits", systemImage: "square.on.square.badge.person.crop")
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
                        Label("Darstellung", systemImage: "a.magnify")
                    }
                    NavigationLink {
                        Form {
                            Section {
                                if elemente.spotlightEintraegeVorhanden {
                                    LabelButton(text: "Alle Spotlight-Sucheinträge löschen", symbol: "trash", action: {
                                        await elemente.loescheSpotlightEintraege()
                                    }, role: .destructive)
                                } else {
                                    LabelButton(text: "Spotlight-Sucheinträge wiederherstellen", symbol: "text.magnifyingglass", action: {
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
                        Label("Speicher", systemImage: "internaldrive")
                    }
                }
                if auth.verifiziert == true {
                    Section {
                        if auth.email != nil {
                            LabelButton(text: "Abmelden", symbol: "rectangle.portrait.and.arrow.right", action: {
                                do {
                                    try await auth.abmelden()
                                } catch {
                                    titel = "Abmeldevorgang fehlgeschlagen"
                                    nachricht = error.localizedDescription
                                    zeigeAlert = true
                                }
                            }, role: .destructive)
                        }
                        LabelButton(text: "Abmelden und Konto löschen", symbol: "trash", action: {
                            do {
                                try await auth.abmelden(loeschen: true)
                            } catch {
                                titel = "Abmeldevorgang fehlgeschlagen"
                                nachricht = error.localizedDescription
                                zeigeAlert = true
                            }
                        }, role: .destructive)
                    }
                }
                Section {
                    link(link: "https://appstore.com", text: "Feedback", systemImage: "star.bubble")
                    link(link: "https://neodym.app", text: "Website", systemImage: "globe")
                    link(link: "https://instagram.com/neodym_app", text: "Instagram", systemImage: nil)
                } footer: {
                    VStack(alignment: .leading) {
                        if store.hatBerechtigung != true {
                            Text("Benutzer ID: \(auth.id ?? "Fehler")")
                        }
                        Text("Version: 1.1")
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
    func link(link: String, text: String, systemImage: String? = nil) -> some View {
        if let url = URL(string: link) {
            Link(destination: url) {
                HStack {
                    Label {
                        Text(text)
                            .foregroundStyle(Color(UIColor.label))
                    } icon: {
                        if let s = systemImage {
                            Image(systemName: s)
                        } else {
                            Image(.insta)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
            }
        }
    }
}

//
//  KontoVerwalten.swift
//  Neodym
//
//  Created by Max Eckstein on 13.06.23.
//

import SwiftUI
import PhotosUI

struct KontoVerwalten: View {
    
    @Environment(\.dismiss) var schließen
    
    @State var name: String
    @State var profilbild: UIImage?
    // Um beim Sicherungsvorgang zu überprüfen, ob der Name sich verändert hat
    // Außerdem kann so Veränderung an das Unterliegende View weitergegeben werden
    @Binding var alterName: String
    @Binding var altesProfilbild: UIImage?
    
    // Status
    @State private var speicherVorgang = false
    @State private var benutzerHatEtwasVeraendert = false
    @State private var benutzerHatEtwasVeraendertWarnung = false
    @State private var alternativerFehlerTitel = ""
    @State private var alternativerFehlerText = ""
    @State private var zeigeFehlerPopUp = false
    
    @State private var profilBildPicker: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            ZStack{
                Color.indigo
                    .frame(width: 50, height: 50)
                    .cornerRadius(25)
                    .offset(x: 130)
                Color.indigo
                    .frame(width: 50, height: 50)
                    .cornerRadius(25)
                    .offset(x: -130)
                PhotosPicker(selection: $profilBildPicker, matching: .images) {
                    if let profilbild {
                        Image(uiImage: profilbild)
                            .resizable()
                            .cornerRadius(75)
                    } else {
                        Image(.warnung)
                            .resizable()
                    }
                }
                .frame(width: 150, height: 150)
            }.onChange(of: profilBildPicker) {
                Task {
                    if let daten = try? await profilBildPicker?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: daten) {
                            profilbild = uiImage
                            benutzerHatEtwasVeraendert = true
                        }
                    }
                }
            }
            Form {
                HStack {
                    Text("Auf PREMIUM upgraden")
                    Spacer()
                    Text("PREMIUM")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing))
                }
                Section {
                    TextField("Dein Vorname", text: $name)
                        .onChange(of: name) {
                            benutzerHatEtwasVeraendert = true
                        }
                }
                Section {
                    Button(role: .destructive){
                        Task {
                            if let fehler = await AuthManager.abmelden(kontoLoeschen: true) {
                                alternativerFehlerTitel = "Abmeldevorgang fehlgeschlagen"
                                alternativerFehlerText = fehler
                                zeigeFehlerPopUp = true
                            }
                        }
                    } label: {
                        HStack {
                            Text("Konto löschen / Abo beenden")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                    Button(role: .destructive){
                        Task {
                            if let fehler = await AuthManager.abmelden() {
                                alternativerFehlerTitel = "Abmeldevorgang fehlgeschlagen"
                                alternativerFehlerText = fehler
                                zeigeFehlerPopUp = true
                            }
                        }
                    } label: {
                        HStack {
                            Text("Abmelden")
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            }
            .navigationTitle("Konto")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Button(benutzerHatEtwasVeraendert ? "Abbrechen" : "Schließen") {
                        if !benutzerHatEtwasVeraendert {
                            schließen()
                        } else {
                            benutzerHatEtwasVeraendertWarnung = true
                            zeigeFehlerPopUp = true
                        }
                    }
                }
                if benutzerHatEtwasVeraendert {
                    ToolbarItem(placement: .navigationBarTrailing){
                        if !speicherVorgang {
                            Button {
                                Task {
                                    await sichereAenderungen()
                                }
                            } label: {
                                Text("Sichern")
                            }
                        } else {
                            ProgressView()
                                .tint(.pink)
                        }
                    }
                }
            }
            .alert(benutzerHatEtwasVeraendertWarnung ? "Ungesicherte Änderungen" : alternativerFehlerTitel, isPresented: $zeigeFehlerPopUp) {
                if benutzerHatEtwasVeraendertWarnung {
                    Button("Abbrechen", role: .cancel, action: {
                        zeigeFehlerPopUp = false
                        benutzerHatEtwasVeraendertWarnung = false
                    })
                    Button("Fortfahren", role: .destructive, action: {
                        schließen()
                    })
                } else {
                    Button("Okay", action: {
                        zeigeFehlerPopUp = false
                    })
                }
            } message: {
                if benutzerHatEtwasVeraendertWarnung {
                    Text("Alle Änderungen die du vorgenommen hast werden verworfen und nicht gespeichert. Möchtest du fortfahren?")
                } else {
                    Text(alternativerFehlerText)
                }
            }
        }
    }
    
    private func sichereAenderungen() async {
        speicherVorgang = true
        // Prüfen, ob sich der Name verändert hat
        if name != alterName {
            // Versuche den Namen zu speichern
            if let fehler = await AuthManager.aendereNamen(zu: name) {
                speicherVorgang = false
                alternativerFehlerText = fehler
                alternativerFehlerTitel = "Sicherungsvorgang fehlgeschlagen"
                zeigeFehlerPopUp = true
                return
            }
            // Alten Namen updaten
            alterName = name
        }
        if altesProfilbild != profilbild {
            guard let profilbild, let daten = profilbild.pngData() else {
                speicherVorgang = false
                alternativerFehlerText = "Das Bild konnte nicht korrekt eingelesen oder verschlüsselt werden"
                alternativerFehlerTitel = "Sicherungsvorgang fehlgeschlagen"
                zeigeFehlerPopUp = true
                return
            }
            if let fehler = await StorageManager.speichereProfilbild(daten) {
                speicherVorgang = false
                alternativerFehlerText = fehler
                alternativerFehlerTitel = "Sicherungsvorgang fehlgeschlagen"
                zeigeFehlerPopUp = true
                return
            }
            // Altes Profilbild updaten
            altesProfilbild = profilbild
        }
        speicherVorgang = false
        schließen()
    }
}

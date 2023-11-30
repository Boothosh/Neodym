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
    
    @State var name: String
    @State var profilbild: UIImage?
    
    @State private var meldetAb = false
    @State private var loescht = false
    
    @State private var zeigeAlert = false
    @State private var titel = ""
    @State private var nachricht = ""
    
    @ObservedObject var benutzer: Benutzer
    @State private var profilBildPicker: PhotosPickerItem?
    @AppStorage("temperaturFormat") var temperaturFormat = "kelvin"
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        if let profilbild {
                            PhotosPicker(selection: $profilBildPicker, matching: .images) {
                                Image(uiImage: profilbild)
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(35)
                            }
                            .frame(width: 70, height: 70)
                            .onChange(of: profilBildPicker) {
                                Task {
                                    if let daten = try? await profilBildPicker?.loadTransferable(type: Data.self) {
                                        if let uiImage = UIImage(data: daten) {
                                            self.profilbild = uiImage
                                        }
                                        await sichereBild()
                                    }
                                }
                            }
                        } else {
                            Color.gray
                                .frame(width: 70, height: 70)
                                .cornerRadius(35)
                                .redacted(reason: .placeholder)
                                .animierterPlatzhalter(isLoading: Binding.constant(true))
                        }
                        VStack(alignment: .leading){
                            TextField("Name", text: $name, onEditingChanged: sichereNamen)
                                .font(.title)
                                .underline(color: Color.gray.opacity(0.5))
                                .textFieldStyle(.plain)
                            Text(benutzer.email ?? "Schul-Account")
                                .font(.caption)
                        }
                        Spacer()
                        Image(.krone)
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                }
                Section {
                    NavigationLink {
                        List {
                            Section("Verantwortlich"){
                                VStack(alignment: .leading){
                                    Text("Max Eckstein")
                                    Text("Erwinstraße 56")
                                }
                            }
                            Section("Kontakt"){
                                if let url = URL(string: "tel:07615904611") {
                                    Link(destination: url, label: {Text("0761 5904611")})
                                }
                                if let url = URL(string: "mailto:team@chemie.app") {
                                    Link(destination: url, label: {Text("team@chemie.app")})
                                }
                            }
                        }.navigationTitle("Impressum")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label(title: {Text("Impressum")}, icon: {Image(systemName: "person")})
                    }
                    NavigationLink {
                        List {
                            Text("Sehr rechtlich korrekter Text.")
                        }.navigationTitle("ABG")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label(title: {Text("ABG")}, icon: {Image(systemName: "scroll")})
                    }
                    NavigationLink {
                        List {
                            Section("Bildquellen"){
                                HStack{
                                    Image(.ätzend)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-acid.svg")
                                        .font(.caption)
                                }
                                HStack{
                                    Image(.brandfördernd)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-rondflam.svg")
                                        .font(.caption)
                                }
                                HStack{
                                    Image(.entzündlich)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-flamme.svg")
                                        .font(.caption)
                                }
                                HStack{
                                    Image(.gasflasche)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-bottle.svg")
                                        .font(.caption)
                                }
                                HStack{
                                    Image(.gesundheitsschädlich)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-silhouette.svg")
                                        .font(.caption)
                                }
                                HStack{
                                    Image(.reizend)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-exclam.svg")
                                        .font(.caption)
                                }
                                HStack{
                                    Image(.umweltschädlich)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-pollu.svg")
                                        .font(.caption)
                                }
                            }
                        }.navigationTitle("Credits")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label(title: {Text("Credits")}, icon: {Image(systemName: "square.on.square.badge.person.crop")})
                    }
                }
                Section {
                    NavigationLink {
                        Form {
                            Picker("Temperatur", selection: $temperaturFormat) {
                                Text("Kelvin").tag("kelvin")
                                Text("Celsius").tag("celsius")
                                Text("Fahrenheit").tag("fahrenheit")
                            }
                        }.navigationTitle("Darstellung")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label(title: {Text("Darstellung")}, icon: {Image(systemName: "a.magnify")})
                    }
                }
                Section {
                    Button(role: .destructive){
                        Task {
                            meldetAb = true
                            if let fehler = await AuthManager.abmelden() {
                                titel = "Abmeldevorgang fehlgeschlagen"
                                nachricht = fehler
                                zeigeAlert = true
                            }
                            meldetAb = false
                        }
                    } label: {
                        HStack {
                            Text("Abmelden")
                            Spacer()
                            if meldetAb {
                                ProgressView()
                                    .tint(.pink)
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    }
                    Button(role: .destructive){
                        Task {
                            loescht = true
                            if let fehler = await AuthManager.abmelden(kontoLoeschen: true) {
                                titel = "Abmeldevorgang fehlgeschlagen"
                                nachricht = fehler
                                zeigeAlert = true
                            }
                            loescht = false
                        }
                    } label: {
                        HStack {
                            Text("Konto löschen")
                            Spacer()
                            if loescht {
                                ProgressView()
                                    .tint(.pink)
                            } else {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                Section {
                    if let url = URL(string: "https://appstore.com") {
                        Link(destination: url) {
                            HStack {
                                Text("Feedback")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                    }
                    if let url = URL(string: "https://neodym.com") {
                        Link(destination: url) {
                            HStack {
                                Text("Website")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                    }
                    if let url = URL(string: "https://github.com") {
                        Link(destination: url) {
                            HStack {
                                Text("Quellcode")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .listStyle(.insetGrouped)
            .task {
                profilbild = await StorageManager.ladeProfilbild()
            }
            .alert(titel, isPresented: $zeigeAlert, actions: {
                Button {
                    zeigeAlert = false
                } label: {
                    Text("Okay")
                }
            }, message: {Text(nachricht)})
        }
    }
    
    func sichereBild() async {
        guard let profilbild else { return }
        self.profilbild = nil
        if let fehler = await StorageManager.speichereProfilbild(profilbild) {
            self.profilbild = benutzer.bild
            titel = "Sicherungsvorgang fehlgeschlagen"
            nachricht = fehler
            zeigeAlert = true
            return
        }
        self.profilbild = profilbild
        benutzer.bild = profilbild
    }
    
    func sichereNamen(gradeErstFokussiert: Bool) {
        if !gradeErstFokussiert && benutzer.name != name {
            Task {
                // Sichere Namen
                if let nachricht = await AuthManager.aendereNamen(zu: name) {
                    self.nachricht = nachricht
                    self.titel = "Fehler beim Sichern des neuen Namens"
                    self.zeigeAlert = true
                } else {
                    benutzer.name = name
                }
            }
        }
    }
}

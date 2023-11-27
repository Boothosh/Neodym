//
//  Einstellungen.swift
//  Neodym
//
//  Created by Max Eckstein on 13.06.23.
//

import SwiftUI
import Setting
import FirebaseAuth
import FirebaseStorage

struct Einstellungen: View {
    
    @State private var zeigeAccountEinstellungen = false
    
    @State private var profilbild: UIImage?
    @State private var profilbildGeladen = false
    @State private var name = Auth.auth().currentUser?.displayName ?? "Fehler"
    @State private var emailOderSchulaccount = Auth.auth().currentUser?.email ?? "Schul-Account"
    
    var body: some View {
        SettingStack {
            SettingPage(title: "Einstellungen") {
                SettingGroup{
                    SettingCustomView (titleForSearch: "Konto"){
                        HStack {
                            if let profilbild {
                                Image(uiImage: profilbild)
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(35)
                            } else if profilbildGeladen {
                                Image(.warnung)
                                    .resizable()
                                    .frame(width: 70, height: 70)
                            } else {
                                Color.gray
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(35)
                                    .redacted(reason: .placeholder)
                                    .animierterPlatzhalter(isLoading: Binding.constant(true))
                            }
                            VStack(alignment: .leading){
                                Text(name)
                                    .font(.title)
                                Text(emailOderSchulaccount)
                                    .font(.caption)
                            }
                            Spacer()
                            Text("PREMIUM")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing))
                        }.padding()
                            .onTapGesture {
                                zeigeAccountEinstellungen = true
                            }
                    }
                }
                SettingGroup{
                    SettingPage(title: "Impressum") {
                        SettingCustomView {
                            VStack(alignment: .leading){
                                Text("Aironex GmbH")
                                    .padding(.bottom, 5)
                                Text("Verantworlich")
                                    .underline()
                                    .padding(.bottom, 1)
                                Text("Max Eckstein")
                                Text("Matteo Zanolli")
                                    .padding(.bottom, 5)
                                Text("Kontakt")
                                    .underline()
                                    .padding(.bottom, 1)
                                Text("0761 5904611")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        guard let url = URL(string: "tel:07615904611") else { return }
                                        UIApplication.shared.open(url)
                                    }
                                Text("team@chemie.app")
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        guard let url = URL(string: "mailto:team@chemie.app") else { return }
                                        UIApplication.shared.open(url)
                                    }
                            }.padding(.leading, 20)
                                .padding(.top, 10)
                        }
                    }.previewIcon("person")
                    SettingPage(title: "AGB") {
                        
                    }.previewIcon("scroll")
                    SettingPage(title: "Credits") {
                        SettingGroup (header: "Einstellungen-PlugIn"){
                            SettingText(title: """
                            MIT License

                            Copyright (c) 2023 A. Zheng

                            Permission is hereby granted, free of charge, to any person obtaining a copy
                            of this software and associated documentation files (the "Software"), to deal
                            in the Software without restriction, including without limitation the rights
                            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                            copies of the Software, and to permit persons to whom the Software is
                            furnished to do so, subject to the following conditions:

                            The above copyright notice and this permission notice shall be included in all
                            copies or substantial portions of the Software.

                            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                            SOFTWARE.
                            """)
                        }
                        SettingGroup (header: "Bildquellen") {
                            SettingCustomView(titleForSearch: "GHS Ätzend"){
                                HStack{
                                    Image(.ätzend)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-acid.svg")
                                        .font(.caption)
                                }.padding()
                            }
                            SettingCustomView(titleForSearch: "GHS Brandfördernd"){
                                HStack{
                                    Image(.brandfördernd)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-rondflam.svg")
                                        .font(.caption)
                                }.padding()
                            }
                            SettingCustomView(titleForSearch: "GHS Entzündlich"){
                                HStack{
                                    Image(.entzündlich)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-flamme.svg")
                                        .font(.caption)
                                }.padding()
                            }
                            SettingCustomView(titleForSearch: "GHS Gasflasche"){
                                HStack{
                                    Image(.gasflasche)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-bottle.svg")
                                        .font(.caption)
                                }.padding()
                            }
                            SettingCustomView(titleForSearch: "GHS Gesundheitsschädlich"){
                                HStack{
                                    Image(.gesundheitsschädlich)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-silhouette.svg")
                                        .font(.caption)
                                }.padding()
                            }
                            SettingCustomView(titleForSearch: "GHS Reizend"){
                                HStack{
                                    Image(.reizend)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-exclam.svg")
                                        .font(.caption)
                                }.padding()
                            }
                            SettingCustomView(titleForSearch: "GHS Umweltschädlich"){
                                HStack{
                                    Image(.umweltschädlich)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    Text("https://de.wikipedia.org/wiki/Datei:GHS-pictogram-pollu.svg")
                                        .font(.caption)
                                }.padding()
                            }
                        }
                    }
                        .previewIcon("square.on.square.badge.person.crop")
                }
                SettingGroup {
                    SettingPage(title: "Darstellung"){
                        SettingGroup {
                            
                        }
                    }.previewIcon("a.magnify")
                }
                SettingGroup {
                    SettingButton(title: "Feedback") {
                        guard let url = URL(string: "https://appstore.com") else { return }
                        UIApplication.shared.open(url)
                    }
                    SettingButton(title: "Website") {
                        guard let url = URL(string: "https://chemie.app") else { return }
                        UIApplication.shared.open(url)
                    }
                    SettingButton(title: "Quellcode") {
                        guard let url = URL(string: "https://github.com") else { return }
                        UIApplication.shared.open(url)
                    }
                }
            }
        }.sheet(isPresented: $zeigeAccountEinstellungen) {
            KontoVerwalten(name: name, profilbild: profilbild, alterName: $name, altesProfilbild: $profilbild)
        }
        .task {
            profilbild = await StorageManager.ladeProfilbild()
            profilbildGeladen = true
        }
    }
}

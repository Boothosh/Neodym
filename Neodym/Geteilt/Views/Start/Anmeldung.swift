//
//  Anmeldung.swift
//  Neodym
//
//  Created by Max Eckstein on 05.06.23.
//

import SwiftUI

struct Anmeldung: View {
    
    @State private var email = ""
    @State private var passwort = ""
    @State private var lizenz = ""
    @State private var vorname = ""
    @State private var ladeVorgang = false
    
    @State private var errorNachricht: String? = nil
    @State private var zeigeError: Bool = false
    
    @State private var fehlenderLizenzSchluessel = false
    @State private var fehlendeEmail = false
    @State private var fehlendesPasswort = false
    @State private var fehlenderVorname = false
    
    let anmeldeArt: AnmeldeArt
    
    var body: some View {
        VStack {
            HStack {
                Text(anmeldeArt == .registrieren ? "Registrieren" : anmeldeArt == .anmelden ? "Anmelden" : "Über Schule anmelden")
                    .foregroundColor(.indigo)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                Spacer()
            }
            
            VStack(spacing: 15){
                
                if anmeldeArt == .schule {
                    TextField("Lizenz-Schlüssel", text: $lizenz)
                        .modifier(CustomTextFeld(error: $fehlenderLizenzSchluessel))
                        .onChange(of: lizenz) {
                            fehlenderLizenzSchluessel = false
                        }
                } else {
                    TextField("Deine E-Mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .modifier(CustomTextFeld(error: $fehlendeEmail))
                        .onChange(of: email) {
                            fehlendeEmail = false
                        }
                    SecureField("Dein Passwort", text: $passwort)
                        .textContentType(anmeldeArt == .registrieren ? .newPassword : .password)
                        .modifier(CustomTextFeld(error: $fehlendesPasswort))
                        .onChange(of: passwort) {
                            fehlendesPasswort = false
                        }
                        .onSubmit {
                            if anmeldeArt == .anmelden {
                                anmeldenOderRegistrieren()
                            }
                        }
                }
                
                if anmeldeArt != .anmelden {
                    Divider()
                        .background(.pink)
                        .padding(.horizontal, 20)
                    
                    TextField("Wie sollen wir dich nennen?", text: $vorname)
                        .modifier(CustomTextFeld(error: $fehlenderVorname))
                        .onChange(of: vorname) {
                            fehlenderVorname = false
                        }
                        .onSubmit {
                            anmeldenOderRegistrieren()
                        }
                }
                
                Spacer()
                Button {
                    anmeldenOderRegistrieren()
                } label: {
                    HStack{
                        Spacer()
                        Text(anmeldeArt == .registrieren ? "Registrieren" : "Anmelden")
                            .foregroundColor(.black)
                            .font(.title3)
                        Spacer()
                        if !ladeVorgang {
                            Image(.weiterPfeil)
                                .resizable()
                                .frame(width: 35, height:35)
                        } else {
                            ProgressView()
                                .tint(.pink)
                                .frame(width: 35, height:35)
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 60)
                    .background(.white)
                    .cornerRadius(15)
                    .shadow(radius: 7)
                }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        .frame(maxWidth: 700)
        .alert("Fehler", isPresented: $zeigeError) {
            Button {
                zeigeError = false
                errorNachricht = nil
            } label: {
                Text("Okay")
            }
        } message: {
            if let error = errorNachricht {
                Text(error)
            } else {
                Text("Wir wissen nichts Näheres über die Ursache des Fehlers.")
            }
        }
        
    }
        
    func anmeldenOderRegistrieren(){
        Task {
            ladeVorgang = true
            switch anmeldeArt {
                case .schule:
                    // Prüfen, dass alle benötigten Felder ausgefüllt sind
                    guard lizenz != "" else { fehlenderLizenzSchluessel = true; break }
                    guard vorname != "" else { fehlenderVorname = true; break }
                    // Anmeldung versuchen, ansonsten Fehler anzeigen
                    errorNachricht = await AuthManager.registrieren(mitLizenz: lizenz, vorname: vorname)
                case .anmelden:
                    // Prüfen, dass alle benötigten Felder ausgefüllt sind
                    guard email != "" else { fehlendeEmail = true; break }
                    guard passwort != "" else { fehlendesPasswort = true; break }
                    // Anmeldung versuchen, ansonsten Fehler anzeigen
                    errorNachricht = await AuthManager.anmelden(email: email, passwort: passwort)
                case .registrieren:
                    // Prüfen, dass alle benötigten Felder ausgefüllt sind
                    guard email != "" else { fehlendeEmail = true; break }
                    guard passwort != "" else { fehlendesPasswort = true; break }
                    guard vorname != "" else { fehlenderVorname = true; break }
                    // Anmeldung versuchen, ansonsten Fehler anzeigen
                    errorNachricht = await AuthManager.registrieren(email: email, passwort: passwort, vorname: vorname)
            }
            // Zeige Fehler, wenn es einen gegeben hat
            if errorNachricht != nil {
                zeigeError = true
            }
            ladeVorgang = false
        }
    }
    
}

enum AnmeldeArt {
    case schule, anmelden, registrieren
}

struct CustomTextFeld: ViewModifier {
    
    @Environment(\.colorScheme) private var colorScheme
    @Binding var error: Bool
    
    func body(content: Content) -> some View {
        content
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 30)
            .frame(height: 60)
            .background(colorScheme == .dark ? Color(UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.7))  : .white)
            .cornerRadius(15)
            .overlay(error ? RoundedRectangle(cornerRadius: 15).stroke(.red, lineWidth: 1) : nil)
            .shadow(radius: 7)
    }
}

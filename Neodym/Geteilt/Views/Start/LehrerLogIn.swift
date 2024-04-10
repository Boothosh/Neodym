//
//  LehrerLogIn.swift
//  Neodym
//
//  Created by Max Eckstein on 14.03.24.
//

import SwiftUI

struct LehrerLogIn: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(NeoAuth.self) private var auth
    
    @State private var email = ""
    @State private var passwort = ""
    
    @State private var ladeVorgangAnmelden = false
    @State private var ladeVorgangRegistrieren = false
    @State private var emailLeer = false
    @State private var passwortLeer = false
    @State private var errorNachricht: String? = nil
    @State private var zeigeError: Bool = false
    
    @State private var registrierenAusgewaelt = true
    
    @State private var zeigePasswortZuruecksetzen = false
    
    var body: some View {
        VStack(spacing: 10){
            HStack {
                Text("Lehrer:innen Zugang")
                    .foregroundColor(.indigo)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .underline()
                Spacer()
            }
            Picker(selection: $registrierenAusgewaelt) {
                Text("Registrieren")
                    .tag(true)
                Text("Anmelden")
                    .tag(false)
            } label: {
                
            }.pickerStyle(.segmented)
                .padding(.bottom)
            if registrierenAusgewaelt {
                VStack(alignment: .leading, spacing: 5){
                    Text("\(Image(systemName: "info.circle")) Schritte zum Erstellen eines Lehrer:innen-Kontos:")
                    HStack{Spacer()}
                    Text("\(Image(systemName: auth.angemeldet == true ? "checkmark.circle" : "circle")) Erstellen Sie einen Account mit Ihrer dienstlichen E-Mail-Adresse.")
                    Text("\(Image(systemName: auth.verifizierteEmail == true ? "checkmark.circle" : "circle")) Verifizieren Sie Ihre E-Mail-Adresse.")
                    HStack{Spacer()}
                    Text("Anschließend müssen wir Prüfen, ob Ihre E-Mail-Adresse einer Bildungseinrichtung zugeordnet werden kann. Ist dies der Fall, wird Ihr Konto freigeschaltet! Diese Prüfung kann 24 Stunden dauern.")
                }
                .padding()
                .background(Color.blue.opacity(0.3))
                .cornerRadius(15)
            }
            TextField("E-Mail", text: $email, prompt: Text("Ihre Schul-E-Mail-Adresse"))
                .modifier(CustomTextFeld(error: $emailLeer))
                .onChange(of: email) { _, _ in
                    emailLeer = false
            }
            SecureField("Passwort", text: $passwort, prompt: Text("Ihr Passwort"))
                .modifier(CustomTextFeld(error: $passwortLeer))
                .onChange(of: passwort) { _, _ in
                    emailLeer = false
                }
                .onSubmit {
                    registrierenAusgewaelt ? registieren() : anmelden()
                }
            Spacer()
            AnmeldeButton(laden: registrierenAusgewaelt ? $ladeVorgangRegistrieren : $ladeVorgangAnmelden, text: registrierenAusgewaelt ? "Registrieren" : "Anmelden") {
                registrierenAusgewaelt ? registieren() : anmelden()
            }
            .disabled(registrierenAusgewaelt ? ladeVorgangRegistrieren : ladeVorgangAnmelden)
            .keyboardShortcut(.defaultAction)
            if !registrierenAusgewaelt {
                Button {
                    zeigePasswortZuruecksetzen = true
                } label: {
                    Text("Passwort vergessen?")
                        .foregroundStyle(.blue)
                }.sheet(isPresented: $zeigePasswortZuruecksetzen) {
                    PasswortZuruecksetzen(email: $email)
                        .environment(auth)
                }
            }
        }.padding(.horizontal)
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
            }.sheet(isPresented: $zeigePasswortZuruecksetzen) {
                PasswortZuruecksetzen(email: $email)
                    .environment(auth)
            }
            .animation(.easeInOut, value: registrierenAusgewaelt)
    }
    
    func anmelden() {
        guard email != "" else { emailLeer = true; return }
        guard passwort != "" else { passwortLeer = true; return }
        Task {
            ladeVorgangAnmelden = true
            do {
                try await auth.anmelden(email: email, passwort: passwort)
            } catch {
                errorNachricht = error.localizedDescription
                zeigeError = true
            }
            ladeVorgangAnmelden = false
        }
    }
    
    func registieren() {
        guard email != "" else { emailLeer = true; return }
        guard passwort != "" else { passwortLeer = true; return }
        Task {
            ladeVorgangRegistrieren = true
            do {
                try await auth.registrierenMitAnmeldedaten(email: email, passwort: passwort)
            } catch {
                errorNachricht = error.localizedDescription
                zeigeError = true
            }
            ladeVorgangRegistrieren = false
        }
    }
}

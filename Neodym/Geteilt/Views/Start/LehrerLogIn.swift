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
    
    @State private var zeigePasswortZuruecksetzen = false
    
    var body: some View {
        VStack(spacing: 10){
            HStack {
                Text("Lehrer Zugang")
                    .foregroundColor(.indigo)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                Spacer()
            }
            HStack {
                Text("Bitte tragen Sie im folgenden Textfeld Ihre schulische E-Mail-Adresse ein. So kann verifiziert werden, dass Sie eine Lehrkraft sind.")
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            TextField("E-Mail", text: $email, prompt: Text("Ihre Schul-E-Mail-Adresse"))
                .modifier(CustomTextFeld(error: $emailLeer))
                .onChange(of: email) { _, _ in
                    emailLeer = false
            }.padding(.vertical)
            SecureField("Passwort", text: $passwort, prompt: Text("Ihr Passwort"))
                .modifier(CustomTextFeld(error: $passwortLeer))
                .onChange(of: passwort) { _, _ in
                    emailLeer = false
                }
                .onSubmit {
                    registieren()
                }
            Spacer()
            HStack {
                AnmeldeButton(laden: $ladeVorgangAnmelden, text: "Anmelden") {
                    anmelden()
                }.disabled(ladeVorgangRegistrieren)
                Divider()
                    .background(.pink)
                AnmeldeButton(laden: $ladeVorgangRegistrieren, text: "Registrieren") {
                    registieren()
                }.disabled(ladeVorgangAnmelden)
                .keyboardShortcut(.defaultAction)
            }.frame(height: 60)
            HStack {
                Button {
                    zeigePasswortZuruecksetzen = true
                } label: {
                    Text("Passwort vergessen?")
                        .foregroundStyle(.blue)
                }.sheet(isPresented: $zeigePasswortZuruecksetzen) {
                    PasswortZuruecksetzen(email: $email)
                        .environment(auth)
                }
                Spacer()
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

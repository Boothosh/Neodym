//
//  PasswortZuruecksetzen.swift
//  Neodym
//
//  Created by Max Eckstein on 30.11.23.
//

import SwiftUI

struct PasswortZuruecksetzen: View {
    
    @Environment(NeoAuth.self) private var auth
    @Binding var email: String
    
    @Environment(\.dismiss) var schließen
    
    @State private var ladeVorgang = false
    @State private var fehlendeEmail = false
    @State private var alertTitel = ""
    @State private var alertText = ""
    @State private var zeigeAlert = false
    
    func passwortZuruecksetzen(){
        Task {
            if email.trimmingCharacters(in: [" "]) != "" && !ladeVorgang {
                ladeVorgang = true
                do {
                    try await auth.passwortZuruecksetzen(email)
                    alertTitel = "Erfolg"
                    alertText = "Halte in deinem E-Mail-Postfach nach einer E-Mail von noreply@neo-datenbank.firebaseapp.com ausschau!"
                } catch {
                    alertTitel = "Fehler"
                    alertText = error.localizedDescription
                }
                zeigeAlert = true
                ladeVorgang = false
            } else {
                fehlendeEmail = true
            }
            
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Passwort zurücksetzten")
                        .foregroundColor(.indigo)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Spacer()
                }
                TextField("Deine E-Mail", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .modifier(CustomTextFeld(error: $fehlendeEmail))
                    .onChange(of: email) {
                        fehlendeEmail = false
                    }
                    .onSubmit {
                        passwortZuruecksetzen()
                    }
                Spacer()
                Button {
                    passwortZuruecksetzen()
                } label: {
                    HStack{
                        Spacer()
                        Text("E-Mail zur Zurücksetzung des Passworts senden")
                            .foregroundColor(.black)
                            .font(.body)
                            .multilineTextAlignment(.center)
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
                    .alert(alertTitel, isPresented: $zeigeAlert, actions: {
                        Button {
                            if alertTitel == "Erfolg" {
                               schließen()
                            }
                        } label: {
                            Text("Okay")
                        }
                    }, message: {Text(alertText)})
            }
            .padding()
            .toolbar {
                Button {
                    schließen()
                } label: {
                    Text("Schließen")
                }
            }
        }
    }
}

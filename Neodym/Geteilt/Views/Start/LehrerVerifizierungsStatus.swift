//
//  LehrerVerifizierungsStatus.swift
//  Neodym
//
//  Created by Max Eckstein on 15.03.24.
//

import SwiftUI

struct LehrerVerifizierungsStatus: View {
    
    @Environment(NeoAuth.self) private var auth
    @Environment(\.dismiss) private var schliessen
    
    @State private var errorNachricht: String? = nil
    @State private var zeigeError: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center){
                if let mail = auth.email {
                    Text("Guten Tag, " + mail + "!")
                    if auth.verifizierteEmail != true {
                        Text("Gehen Sie bitte in Ihr E-Mail-Postfach, und schließen Sie die E-Mail Verifizierung ab!")
                            .multilineTextAlignment(.center)
                        Button("E-Mail erneut senden!") {
                            Task {
                                do {
                                    try await auth.sendeVerifikationsMail()
                                } catch {
                                    errorNachricht = error.localizedDescription
                                    zeigeError = true
                                }
                            }
                        }
                    } else {
                        Text("Bitte warten Sie, bis wir Ihre E-Mail geprüft haben. Wir werden versuchen, Sie einer Schule zuzuordnen, um zu verifizieren, dass Sie eine Lehrkraft sind!")
                            .multilineTextAlignment(.center)
                    }
                    Button {
                        Task {
                            do {
                                auth.verifiziert = try await auth.pruefeIdentitaet("lehrer")
                            } catch {
                                errorNachricht = error.localizedDescription
                                zeigeError = true
                            }
                        }
                    } label: {
                        Text("Account-Status neu laden")
                            .multilineTextAlignment(.center)
                    }
                }
            }.toolbar {
                Button {
                    Task {
                        do {
                            try await auth.abmelden()
                            schliessen()
                        } catch {
                            errorNachricht = error.localizedDescription
                            zeigeError = true
                        }
                    }
                } label: {
                    Text("Abmelden")
                }
            }.alert("Fehler", isPresented: $zeigeError) {
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
    }
}

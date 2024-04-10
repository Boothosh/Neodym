//
//  LizenzLogIn.swift
//  Neodym
//
//  Created by Max Eckstein on 14.03.24.
//

import SwiftUI

struct LizenzLogIn: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(NeoAuth.self) private var auth
    
    @State private var lizenz = ""
    @State private var ladeVorgang = false
    @State private var lizenzLeer = false
    
    @State private var errorNachricht: String? = nil
    @State private var zeigeError: Bool = false
    
    var body: some View {
        VStack(spacing: 10){
            HStack {
                Text("Lizenz einlösen")
                    .foregroundColor(.indigo)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .underline()
                Spacer()
            }
            HStack {
                Text("\(Image(systemName: "info.circle")) Wenn dir deine Lehrer:innen einen Lizenzschlüssel zugeteilt haben, kannst du diesen hier eingeben. Damit erhältst du Zugang zur App.")
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.3))
            .cornerRadius(15)
            .padding(.top)
            TextField("Lizenz", text: $lizenz, prompt: Text("Deine Lizenz"))
                .modifier(CustomTextFeld(error: $lizenzLeer))
                .onSubmit { einloesen() }
                .onChange(of: lizenz){ _, _ in
                    lizenzLeer = false
                }
            Spacer()
            AnmeldeButton(laden: $ladeVorgang, text: "Einlösen") {
                einloesen()
            }.keyboardShortcut(.defaultAction)
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
    
    func einloesen() {
        guard !lizenz.trimmingCharacters(in: [" "]).isEmpty else {
            lizenzLeer = true
            return
        }
        Task {
            ladeVorgang = true
            do {
                try await auth.registrierenMitLizenz(lizenz: lizenz.trimmingCharacters(in: [" "]))
            } catch {
                errorNachricht = error.localizedDescription
                zeigeError = true
                lizenzLeer = true
            }
            ladeVorgang = false
        }
    }
}

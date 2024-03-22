//
//  Willkommen.swift
//  Neodym
//
//  Created by Max Eckstein on 08.06.23.
//

import SwiftUI

struct Willkommen: View {
    
    @Environment(NeoStore.self) private var store
    @Environment(NeoAuth.self) private var auth
    @State private var zeigeWeiterfuehrendesPopUp = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                if auth.angemeldet == true {
                    Text("")
                        .onAppear {
                            zeigeWeiterfuehrendesPopUp = true
                        }
                }
                VStack(spacing: 30){
                    VStack {
                        Spacer()
                        Image("Logo")
                            .resizable()
                            .frame(width: 130, height: 130)
                        VStack(spacing: 2){
                            Text("Willkommen bei")
                            Text("Neodym")
                                .foregroundStyle(.indigo)
                        }
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        Text("Alle Werkzeuge, die man für Chemie braucht.\nIn einer App.")
                            .padding(.top, 5)
                        Spacer()
                    }.foregroundStyle(Color(uiColor: UIColor.label))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 30){
                        let size = abs((geo.size.width - 90)/2)
                        NavigationLink {
                            LizenzLogIn()
                                .environment(auth)
                        } label: {
                            VStack {
                                Image(systemName: "studentdesk")
                                    .font(.system(size: 70))
                                    .fontWeight(.thin)
                                Text("Schüler*in")
                            }
                                .padding()
                                .frame(width: size, height: min(130, size))
                                .background(.green.gradient)
                                .cornerRadius(15)
                        }
                        NavigationLink {
                            LehrerLogIn()
                                .environment(auth)
                        } label: {
                            VStack {
                                Image(systemName: "graduationcap.fill")
                                    .font(.system(size: 70))
                                    .fontWeight(.thin)
                                Text("Lehrkraft")
                            }
                                .padding()
                                .frame(width: size, height: min(130, size))
                                .background(.green.gradient)
                                .cornerRadius(15)
                        }
                    }
                    NavigationLink {
                        Paywall()
                            .environment(store)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Normal fortfahren")
                                .padding()
                            Spacer()
                        }
                    }
                    .background(.blue.gradient)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 30)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: 600)
        }.sheet(isPresented: $zeigeWeiterfuehrendesPopUp) {
            LehrerVerifizierungsStatus()
                .environment(auth)
        }
    }
}

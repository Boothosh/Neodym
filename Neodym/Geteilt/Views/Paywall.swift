//
//  Paywall.swift
//  Neodym
//
//  Created by Max Eckstein on 06.03.24.
//

import SwiftUI
import StoreKit

struct Paywall: View {
    
    @Environment(NeoStore.self) private var store
    @State private var auswahl: Product? = nil
    @State private var bounceCounter: [Product: Int] = [:]
    
    @State private var probeAbo = false
    @State private var istAbo = true
    @State private var buttonMussLaden = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0){
                VStack(spacing: 20){
                    Image("Logo")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .frame(height: 100)
                    Text("Neodym")
                        .font(.largeTitle)
                        .bold()
                    Text("Interaktives Periodensystem, Molekül-Canvas, Chemie-Rechner und vieles mehr – in einer App.")
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.title3.weight(.medium))
                        .padding(.horizontal)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                    HStack {
                        Text("\(Image(systemName: "info.circle")) Um Zugang zur App zu erhalten, musst du entweder ein aktives Abonnement haben oder die App einmalig gekauft haben.")
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    HStack {
                        Text("\(Image(systemName: "iphone"))+\(Image(systemName: "ipad.landscape"))+\(Image(systemName: "macbook"))+\(Image(systemName: "visionpro")): Ein Abo oder Kauf für Zugang auf all deinen Geräten.")
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Abo-Optionen
                    if !store.privatProdukte.isEmpty {
                        VStack(spacing: 10){
                            ForEach(store.privatProdukte){ produkt in
                                VStack(alignment: .leading) {
                                    HStack {
                                        VStack(alignment: .leading){
                                            Text(produkt.displayName)
                                                .font(.headline)
                                            Text("\(produkt.displayPrice)\(produkt.type == .autoRenewable ? "/\(produkt.subscription!.subscriptionPeriod.unit)" : "")")
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        Image(systemName: auswahl == produkt ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(auswahl == produkt ? .white : .gray, .blue)
                                            .font(.title2)
                                            .symbolEffect(.bounce, value: bounceCounter[produkt] ?? 0)
                                    }
                                    Divider()
                                    Text(produkt.description)
                                        .font(.subheadline)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .onTapGesture {
                                    waehleAus(produkt)
                                }
                                .overlay(auswahl == produkt ? RoundedRectangle(cornerRadius: 15).stroke(lineWidth: 2).fill(.blue) : nil)
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        .sensoryFeedback(.selection, trigger: auswahl)
                            .task{
                                await setup()
                            }
                    } else {
                        ProgressView()
                    }
                }
                .padding(.vertical)
            }
            VStack(spacing: 20){
                Button{
                    Task {
                        guard let auswahl else { return }
                        do {
                            let _ = try await store.kauf(auswahl)
                        } catch {
                            
                        }
                    }
                } label: {
                    Group {
                        if !buttonMussLaden {
                            VStack {
                                Text(!istAbo ? "Kaufen" : probeAbo ? "Kostenlos testen" : "Abonnieren")
                                    .font(.title3)
                                    .bold()
                                if let sub = auswahl?.subscription, istAbo {
                                    Text(probeAbo ? "\(String(sub.introductoryOffer?.period.value ?? 1 )) \(sub.introductoryOffer?.period.unit.debugDescription ?? "") kostenlos testen, danach wird der Plan für \(auswahl!.displayPrice)/\(sub.subscriptionPeriod.unit.debugDescription) fortgesetzt, bis er gekündigt wird." : "Plan wird automatisch für \(auswahl!.displayPrice)/\(sub.subscriptionPeriod.unit.debugDescription) fortgesetzt, bis er gekündigt wird.")
                                         .font(.caption)
                                }
                            }
                        } else {
                            ProgressView()
                        }
                    }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .keyboardShortcut(.defaultAction)
                .padding(.horizontal)
                HStack {
                    Link(destination: URL(string: "https://neodym.app/rechtliches#datenschutz")!) {
                        Text("Datenschutz")
                    }
                    Image(systemName: "circle")
                        .font(.caption2)
                    Button("Kauf wiederherstellen") {
                        Task {
                            do {
                                try await store.kaufWiederherstellen()
                            } catch {
                                
                            }
                        }
                    }
                    Image(systemName: "circle")
                        .font(.caption2)
                    Link(destination: URL(string: "https://neodym.app/rechtliches#agb")!) {
                        Text("AGB")
                    }
                }.font(.caption)
                .bold()
            }
                .padding(.vertical)
        }.frame(maxWidth: 600)

    }
    
    func setup() async {
        for i in store.privatProdukte {
            bounceCounter[i] = 0
        }
        waehleAus(store.privatProdukte[1])
    }
    
    func waehleAus(_ produkt: Product) {
        Task {
            if auswahl != produkt {
                withAnimation {
                    auswahl = produkt
                    bounceCounter[produkt] = (bounceCounter[produkt] ?? 0) + 1
                    buttonMussLaden = true
                    istAbo = produkt.type == .autoRenewable
                }
                if istAbo {
                    let x = await produkt.subscription?.isEligibleForIntroOffer ?? false
                    withAnimation {
                        probeAbo = x
                    }
                }
                withAnimation {
                    buttonMussLaden = false
                }
            }
        }
    }
}

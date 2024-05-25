//
//  NeoStore.swift
//  Neodym
//
//  Created by Max Eckstein on 03.03.24.
//

import StoreKit
import SwiftUI

@Observable class NeoStore {
    
    var lifetime:   Product?
    var monatlich:  Product?
    var jaehrlich:  Product?
    
    var lizenzen:     [Product]?
    
    var privatProdukte: [Product] = []
    
    var hatBerechtigung: Bool?
    var hatAbo = false
    
    private var taskHandle: Task<Void, Error>?
    
    func delayedInit() async {
        taskHandle = listenForTransactions()
        await ladeProdukte()
        print("[NeoStore]: delayedInit() abgeschlossen")
    }
    
    @MainActor
    func ladeProdukte() async {
        do {
            lifetime = try await Product.products(for: ["neo_full_lifetime"]).first
            monatlich = try await Product.products(for: ["neo_full_monatlich"]).first
            jaehrlich = try await Product.products(for: ["neo_full_jaehrlich"]).first
            guard let lifetime, let monatlich, let jaehrlich else { return }
            privatProdukte.append(contentsOf: [monatlich, jaehrlich, lifetime])
            lizenzen = try await Product.products(for: ["lizenz_paket_10", "lizenz_paket_50", "lizenz_paket_100"])
            lizenzen?.sort(by: { $0.price < $1.price })
            try await checkeObBerechtigung()
        } catch {
            print(error)
            hatBerechtigung = false
        }
    }
    
    func kauf(_ produkt: Product, _ purchaseAction: PurchaseAction, anzahl: Int = 1) async throws -> Bool {
        let ergebnis = try await purchaseAction(produkt, options: [.quantity(anzahl), .appAccountToken(UUID())])
        switch ergebnis {
            case .success(let verifizierungsErgebnis):
                let transaktion = try checkVerified(verifizierungsErgebnis)
                print(transaktion.hashValue)
                let id = transaktion.productID
                if id == "neo_full_lifetime" || id == "neo_full_monatlich" || id == "neo_full_jaehrlich" {
                    hatBerechtigung = true
                    hatAbo = (id != "neo_full_lifetime")
                } else {
                    let paketAnzahl = id == "lizenz_paket_100" ? 100 : id == "lizenz_paket_50" ? 50 : 10
                    try await NeoFire.kaufeLizenzen(anzahl: anzahl*paketAnzahl, beleg: transaktion.appAccountToken?.uuidString ?? "Fehler")
                }
                await transaktion.finish()
                print("[NeoStore]: Transaktion \(transaktion.id) abgeschlossen!")
                return true
            default:
                return false
        }
    }
    
    func kaufWiederherstellen() async throws {
        try await AppStore.sync()
    }
    
    func checkeObBerechtigung() async throws {
        for await entitlement in Transaction.currentEntitlements {
            let transaktion = try checkVerified(entitlement)
            let id = transaktion.productID
            if id == "neo_full_lifetime" || id == "neo_full_monatlich" || id == "neo_full_jaehrlich" {
                hatBerechtigung = true
                hatAbo = (id != "neo_full_lifetime")
                return
            }
        }
        hatBerechtigung = false
    }
    
    func dealloc() {
        taskHandle?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await verifizierungsErgebnis in Transaction.updates {
                do {
                    let transaktion = try self.checkVerified(verifizierungsErgebnis)
                    let id = transaktion.productID
                    if id == "neo_full_lifetime" || id == "neo_full_monatlich" || id == "neo_full_jaehrlich" {
                        self.hatBerechtigung = true
                        self.hatAbo = (id != "neo_full_lifetime")
                    } else {
                        try await NeoFire.kaufeLizenzen(anzahl: transaktion.purchasedQuantity, beleg: transaktion.appAccountToken?.uuidString ?? "Fehler")
                    }
                    await transaktion.finish()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
            case .unverified:
                throw NutzerFehler.unverifizierterKauf
            case .verified(let safe):
            return safe        }
    }
}

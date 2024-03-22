//
//  NeoStore.swift
//  Neodym
//
//  Created by Max Eckstein on 03.03.24.
//

import StoreKit

@Observable class NeoStore {
    
    var lifetime:   Product?
    var monatlich:  Product?
    var jaehrlich:  Product?
    var lizenz:     Product?
    
    var privatProdukte: [Product] = []
    
    var hatBerechtigung: Bool?
    
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
            try await checkeObBerechtigung()
        } catch {
            print(error)
            hatBerechtigung = false
        }
    }
    
    func kauf(_ produkt: Product, _ anzahl: Int = 1) async throws -> Bool {
        let ergebnis = try await produkt.purchase(options: [.quantity(anzahl)])
        switch ergebnis {
            case .success(let verifizierungsErgebnis):
                let transaktion = try checkVerified(verifizierungsErgebnis)
                let id = transaktion.productID
                if id == "neo_full_lifetime" || id == "neo_full_monatlich" || id == "neo_full_jaehrlich" {
                    hatBerechtigung = true
                }
                await transaktion.finish()
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
                    }
                    await transaktion.finish()
                } catch {
                    print("Transaction failed verification")
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

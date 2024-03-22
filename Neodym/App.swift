//
//  App.swift
//  Neodym
//
//  Created by Max Eckstein on 05.06.23.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck
import FirebaseRemoteConfig
import ConfettiSwiftUI

class MyAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if DEBUG
        return AppCheckDebugProvider(app: app)
#else
        return AppAttestProvider(app: app)
#endif
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      // AppCheck stellt sicher, dass Anfragen an die Datenbank nur beantwortet werden, wenn sie von dieser App ausgehen
      AppCheck.setAppCheckProviderFactory(MyAppCheckProviderFactory())
      
      // Firebase-Projekt Initialisieren
      FirebaseApp.configure()
      
      return true
  }
}

@main
struct NeodymApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var store = NeoStore()
    @State private var auth = NeoAuth()
    @State private var elemente = Elemente()
    @State private var konfetti = 0
    
    var body: some Scene {
        WindowGroup {
            if auth.verifiziert == true || store.hatBerechtigung == true {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    iOSMain()
                        .environment(elemente)
                        .environment(auth)
                        .environment(store)
                        .confettiCannon(counter: $konfetti, num: 150, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 500)
                } else {
                    iPadOSMain()
                        .environment(elemente)
                        .environment(auth)
                        .environment(store)
                        .confettiCannon(counter: $konfetti, num: 150, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 500)
                }
            } else if auth.verifiziert == nil && store.hatBerechtigung == nil {
                ProgressView()
                    .task {
                        await store.delayedInit()
                        await auth.delayedInit()
                        if auth.verifiziert == true || store.hatBerechtigung == true {
                            await elemente.delayedInit()
                        } else {
                            Task.detached {
                                await elemente.delayedInit()
                            }
                        }
                    }
            } else {
                // Benutzer ist nicht angemeldet
                Willkommen()
                    .environment(auth)
                    .environment(store)
                    .onDisappear {
                        if store.hatBerechtigung == true {
                            konfetti += 1
                        }
                    }
            }
        }
    }
}

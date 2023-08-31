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

class MyAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if DEBUG
        let debug = AppCheckDebugProvider(app: app)
        return debug
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
      FirebaseApp.configure()
      return true
  }
}

@main
struct NeodymApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var elementeManager = ElementManager()
    @State var benutzerIstAngemeldet: Bool? = nil
    
    var body: some Scene {
        WindowGroup {
            if benutzerIstAngemeldet == nil {
                ProgressView()
                    .onAppear {
                        Auth.auth().addStateDidChangeListener { benutzerIstAngemeldet = ($1 != nil) }
                    }
            } else if benutzerIstAngemeldet == false {
                // Benutzer ist nicht angemeldet
                Willkommen()
            } else if UIDevice.current.userInterfaceIdiom == .phone {
                // iPhone
                iOSMain(elementeManager: $elementeManager)
            } else {
                // iPad oder Mac
                iPadOSMain(elementeManager: $elementeManager)
            }
        }
    }
}

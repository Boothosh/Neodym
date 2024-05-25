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

#if os(iOS) || os(visionOS)
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
#else

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        return effectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppCheck.setAppCheckProviderFactory(MyAppCheckProviderFactory())
        NSWindow.allowsAutomaticWindowTabbing = false
        FirebaseApp.configure()
    }
    
    // Schließe die App, nachdem das letzte Fenster geschlossen wurde
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
}
#endif

@main
struct NeodymApp: App {
    
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
#else
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
#endif
    @State private var store = NeoStore()
    @State private var auth = NeoAuth()
    @State private var elemente = Elemente()
    @State private var konfetti = 0
    
    var body: some Scene {
        WindowGroup {
            if auth.verifiziert == true || store.hatBerechtigung == true {
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    // iPhone
                    iPhoneRoot()
                        .environment(elemente)
                        .environment(auth)
                        .environment(store)
                        .confettiCannon(counter: $konfetti, num: 150, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 500)
                } else {
                    // iPad
                    iPadRoot()
                        .environment(elemente)
                        .environment(auth)
                        .environment(store)
                        .confettiCannon(counter: $konfetti, num: 150, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 500)
                }
#elseif os(visionOS)
                // Apple Vision Pro
                visionRoot()
                    .environment(elemente)
                    .environment(auth)
                    .environment(store)
                    .confettiCannon(counter: $konfetti, num: 150, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 500)
#elseif os(macOS)
                // Mac
                iPadRoot()
                    .environment(elemente)
                    .environment(auth)
                    .environment(store)
                    .confettiCannon(counter: $konfetti, num: 150, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 500)
                    .background(VisualEffectView().ignoresSafeArea())
#endif
            } else if auth.verifiziert == nil || store.hatBerechtigung == nil {
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
                        // Hiernach muss sichergegangen werden, dass sowohl store.hatBerechtigung als auch auth.verifiziert definiert ist.
                        store.hatBerechtigung = (store.hatBerechtigung ?? false)
                        auth.verifiziert = (auth.verifiziert ?? false)
                        
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
                    .buttonStyle(.plain)
                    .background(.bgr)
            }
        }
        #if os(visionOS)
        .defaultSize(width: 1600, height: 1000)
        #elseif os(macOS)
        .defaultSize(width: 1200, height: 600)
        .windowToolbarStyle(.unified)
        .windowStyle(.titleBar)
        #endif
        
        #if os(macOS)
        Settings {
            if auth.verifiziert == true || store.hatBerechtigung == true {
                Einstellungen()
                    .environment(elemente)
                    .environment(store)
                    .environment(auth)
            } else {
                Text("Melden Sie sich an, um auf die Einstellungen zugreifen zu können.")
            }
        }.defaultSize(width: 700, height: 500)
        #endif
    }
}

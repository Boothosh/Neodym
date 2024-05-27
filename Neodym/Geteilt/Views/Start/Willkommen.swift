//
//  Willkommen.swift
//  Neodym
//
//  Created by Max Eckstein on 08.06.23.
//

import SwiftUI
import SceneKit

struct Willkommen: View {
    
    @State private var szene: SCNScene? = nil
    @State private var zeigeAnmeldeAlternativenSheet = false
    @State private var lehrerPopUp = false
    @State private var navigationPath = NavigationPath()
    @Environment(NeoStore.self) private var store
    @Environment(NeoAuth.self) private var auth
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geo in
                //                if auth.angemeldet == true {
                //                    Text("")
                //                        .onAppear {
                //                            lehrerPopUp = true
                //                        }
                //                }
                VStack(alignment: .center, spacing: 10){
                    VStack(spacing: 2){
                        Text("Willkommen bei")
                        Text("Neodym")
                            .foregroundStyle(.indigo)
                    }
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    if geo.size.height > 750 {
                        VStack(spacing: 25){
                            Image("Logo")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .rotation3DEffect(.degrees(7.5), axis: (x: 1, y: 1, z: 0))
                                .shadow(radius: 10)
                            Text("Alle Werkzeuge, die man für den Chemieunterricht braucht.") +
                            Text("\nIn einer App.")
                                .bold()
                        }.multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .frame(maxWidth: 500)
                    } else {
                        HStack {
                            Image("Logo")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .rotation3DEffect(.degrees(7.5), axis: (x: 1, y: 1, z: 0))
                                .shadow(radius: 10)
                            Spacer()
                                .frame(maxWidth: 50)
                            Text("Alle Werkzeuge, die man für den Chemieunterricht braucht.\nIn einer App.")
                        }.padding(.top, 8)
                            .frame(maxWidth: 500)
                    }
                    Spacer()
                    Spacer()
                    if let szene {
                        SceneView(scene: szene, options: [.autoenablesDefaultLighting])
                            .frame(maxHeight: geo.size.width / 2)
                    } else {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    Spacer()
                    Button {
                        UserDefaults.standard.set(true, forKey: "anmeldungGeskippt")
                        //navigationPath.append("privat")
                    } label: {
                        HStack {
                            Spacer()
                            Text("Fortfahren")
                            Spacer()
                        }
                        .frame(height: 58)
                        .frame(maxWidth: 500)
                        .foregroundStyle(.white)
                        .background(.blue)
                        .cornerRadius(15)
                    }.keyboardShortcut(.defaultAction)
                        .buttonStyle(.plain)
                    //                    #if os(iOS) || os(visionOS)
                    //                    if UIDevice.current.userInterfaceIdiom == .phone {
                    //                        Button {
                    //                            zeigeAnmeldeAlternativenSheet.toggle()
                    //                        } label: {
                    //                            Text("Anmeldealternativen")
                    //                        }
                    //                        .sheet(isPresented: $zeigeAnmeldeAlternativenSheet) {
                    //                            VStack {
                    //                                Text("Anmeldealternativen")
                    //                                    .bold()
                    //                                schuelerButton
                    //                                lehrerButton
                    //                            }
                    //                            .padding()
                    //                            .presentationDetents([.height(200)])
                    //                            .presentationDragIndicator(.visible)
                    //                        }
                    //                    } else {
                    //                        Divider()
                    //                            .background(.indigo)
                    //                            .frame(maxWidth: 350)
                    //                            .overlay {
                    //                                Text("Anmeldealternativen")
                    //                                    .font(.caption2)
                    //                                    .padding(5)
                    //                                    .background(.bgr)
                    //                            }.padding(.vertical, 10)
                    //                        HStack(spacing: 20){
                    //                            schuelerButton
                    //                            lehrerButton
                    //                        }.frame(width: 500)
                    //                    }
                    //                    #else
                    //                    Divider()
                    //                        .background(.indigo)
                    //                        .frame(maxWidth: 350)
                    //                        .overlay {
                    //                            Text("Anmeldealternativen")
                    //                                .font(.caption2)
                    //                                .padding(5)
                    //                                .background(.bgr)
                    //                        }.padding(.vertical, 10)
                    //                    HStack(spacing: 20){
                    //                        schuelerButton
                    //                            .buttonStyle(.plain)
                    //                        lehrerButton
                    //                            .buttonStyle(.plain)
                    //                    }.frame(width: 500)
                    //                    #endif
                }
                .padding()
                .task {
                    Task.detached(priority: .high) {
                        let szene = SCNScene(named: "Neodym.usdz") ?? SCNScene()
                        self.szene = szene
#if os(iOS) || os(visionOS)
                        szene.background.contents = UIColor.bgr
#else
                        szene.background.contents = NSColor.bgr
#endif
                        await MainActor.run {
                            szene.rootNode.simdScale = simd_float3(1.8, 1.8, 1.8)
                            szene.rootNode.childNodes[0].rotation = SCNVector4(1, 0, 0, 0.3)
                            szene.rootNode.animationPlayer(forKey: "a")
                            self.szene = szene
                            self.szene!.rootNode.childNode(withName: "Neodym", recursively: true)!.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 5)))
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxWidth: 700, maxHeight: 800)
            //            .navigationDestination(for: String.self) { art in
            //                switch art {
            //                    case "privat":
            //                        Paywall()
            //                            .environment(store)
            //                    case "lehrer":
            //                        LehrerLogIn()
            //                            .environment(auth)
            //                    case "schueler":
            //                        LizenzLogIn()
            //                            .environment(auth)
            //                    default:
            //                        Text("Fehler")
            //                }
            //            }
            //        }.sheet(isPresented: $lehrerPopUp) {
            //            LehrerVerifizierungsStatus()
            //                .environment(auth)
            //        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
//    
//    var schuelerButton: some View {
//        Button {
//            navigationPath.append("schueler")
//            zeigeAnmeldeAlternativenSheet.toggle()
//        } label: {
//            HStack {
//                Image(systemName: "graduationcap.fill")
//                    .foregroundStyle(.white)
//                    .font(.largeTitle)
//                Text("Als Schüler:in fortfahren")
//                    .fixedSize(horizontal: false, vertical: true)
//                Spacer()
//                Image(systemName: "chevron.forward")
//                    .foregroundStyle(.white)
//                    .font(.largeTitle)
//            }
//            .foregroundStyle(.white)
//            .padding()
//            .frame(height: 58)
//            .background(.blue)
//            .cornerRadius(15)
//        }
//    }
//    
//    var lehrerButton: some View {
//        Button {
//            navigationPath.append("lehrer")
//            zeigeAnmeldeAlternativenSheet.toggle()
//        } label: {
//            HStack {
//                Image(.lehrer)
//                    .foregroundStyle(.white, .green, .green)
//                    .font(.largeTitle)
//                Text("Als Lehrer:in fortfahren")
//                    .fixedSize(horizontal: false, vertical: true)
//                Spacer()
//                Image(systemName: "chevron.forward")
//                    .foregroundStyle(.white)
//                    .font(.largeTitle)
//            }
//            .foregroundStyle(.white)
//            .padding()
//            .frame(height: 58)
//            .background(.blue)
//            .cornerRadius(15)
//        }
//    }
}

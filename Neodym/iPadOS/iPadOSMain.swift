//
//  iPadOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI
import FirebaseAuth

struct iPadOSMain: View {
    
    @Binding var elementeManager: ElementManager
    @State private var ausgewaelterAppBereich: iPadAppBereich? = .elemente
    @State private var systemIstAusgewaelt = true
    
    @State private var suchBegriff: String = ""
    @State private var ausgewaeltesElement: Element? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @ObservedObject var benutzer: Benutzer
    @State private var zeigeEinstellungen = false
    
    var sideBar: some View {
        VStack {
            List(selection: $ausgewaelterAppBereich){
                Label("Elemente", systemImage: "square.grid.4x3.fill")
                    .tag(iPadAppBereich.elemente)
                DisclosureGroup(content: {
                    Label("Stöchiometrie", systemImage: "x.squareroot")
                        .tag(iPadAppBereich.wissen_stoechometrie)
                    Label("Moleküle", systemImage: "circle.hexagonpath.fill")
                        .tag(iPadAppBereich.wissen_molekuele)
                }, label: {
                    Label("Wissen", systemImage: "graduationcap")
                })
                DisclosureGroup(content: {
                    Label("Moleküle zeichnen", systemImage: "pencil.and.ruler")
                        .tag(iPadAppBereich.werkzeug_zeichnen)
                    Label("Molekülmasse ausrechnen", systemImage: "scalemass")
                        .tag(iPadAppBereich.werkzeug_molmasse)
                    Label("Ionengruppe bilden", systemImage: "circle.grid.3x3")
                        .tag(iPadAppBereich.werkzeug_ionengruppe)
                }, label: {
                    Label("Werkzeuge", systemImage: "wrench.and.screwdriver")
                })
                Label("Quiz", systemImage: "brain")
                    .tag(iPadAppBereich.quiz)
            }
            HStack {
                Button {
                    zeigeEinstellungen = true
                } label: {
                    if let profilbild = benutzer.bild {
                        Image(uiImage: profilbild)
                            .resizable()
                            .cornerRadius(20)
                            .frame(width: 40, height: 40)
                    } else {
                        ProgressView()
                            .frame(width: 40, height: 40)
                    }
                    Text(benutzer.name)
                    Spacer()
                    Image(systemName: "gearshape.2")
                }.foregroundStyle(Color(uiColor: .label))
            }.padding(.horizontal)
                .padding(.top)
            .background(Color(.listenHintergrundFarbe))
        }.navigationTitle("Neodym")
            .sheet(isPresented: $zeigeEinstellungen, content: {
                Einstellungen(name: benutzer.name, profilbild: benutzer.bild, benutzer: benutzer)
            })
    }
    
    var hauptcontent: some View {
        NavigationStack {
            switch ausgewaelterAppBereich {
                case .elemente:
                    VStack(alignment: .center){
                        if elementeManager.perioden.isEmpty {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else if systemIstAusgewaelt {
                            System(elementManager: $elementeManager, suchBegriff: $suchBegriff, ausgewaeltesElement: $ausgewaeltesElement)
                                .navigationTitle("Elemente")
                                .task {
                                    if columnVisibility == .doubleColumn {
                                        columnVisibility = .detailOnly
                                    }
                                    ausgewaeltesElement = nil
                                }
                        } else {
                            // DetailView wegen Liste
                            if let ausgewaeltesElement {
                                ElementDetail(element: ausgewaeltesElement)
                            }
                        }
                    }
                        .toolbar {
                            ToolbarItem {
                                Picker("Ansicht", selection: $systemIstAusgewaelt) {
                                    Text("Periodensystem").tag(true)
                                    Text("Liste").tag(false)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                case .wissen_stoechometrie:
                    Wissen()
                case .wissen_molekuele:
                    Wissen()
                case .werkzeug_zeichnen:
                    Molekuelzeichner(elementeManager: $elementeManager)
                case .werkzeug_molmasse:
                    MolekuelmasseRechner(elementManager: $elementeManager)
                case .werkzeug_ionengruppe:
                    IonengruppenBilden(elementManager: $elementeManager)
                case .quiz:
                    QuizView()
                case nil:
                    Text("Wähle einen Bereich der App aus, den du nutzen möchtest!")
            }
        }
    }
    
    var body: some View {
        if ausgewaelterAppBereich == .elemente && !systemIstAusgewaelt {
            NavigationSplitView(columnVisibility: $columnVisibility){
                sideBar
            } content: {
                List(elementeManager.alleElemente.filter({ element in
                    element.name.lowercased().contains(suchBegriff.lowercased()) || element.symbol.lowercased().contains(suchBegriff.lowercased()) || suchBegriff == ""
                }), id: \.self, selection: $ausgewaeltesElement){ element in
                    HStack{
                        Text(element.symbol)
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.bold)
                            .shadow(radius: 5)
                            .frame(width: 60, height: 60)
                            .background(Color(element.klassifikation))
                            .cornerRadius(5)
                            .shadow(radius: 5)
                            .padding(.trailing)
                        VStack(alignment: .leading){
                            Text(element.name)
                                .font(.title3)
                                .foregroundStyle(Color(uiColor: UIColor.label))
                            Text(element.klassifikation)
                                .fontWeight(.bold)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }.searchable(text: $suchBegriff)
                    .navigationTitle("Elemente")
                    .task {
                        print(columnVisibility)
                        if columnVisibility == .detailOnly {
                            columnVisibility = .doubleColumn
                        }
                        withAnimation {
                            ausgewaeltesElement = elementeManager.alleElemente.first!
                        }
                    }
            } detail: {
                hauptcontent
            }.navigationSplitViewStyle(.balanced)
            .task {
                await elementeManager.ladeDatei()
            }
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility){
                sideBar
            } detail: {
                hauptcontent
            }.navigationSplitViewStyle(.balanced)
            .task {
                await elementeManager.ladeDatei()
            }
        }
    }
    
    enum iPadAppBereich: Hashable {
        case elemente
        case wissen_stoechometrie, wissen_molekuele
        case werkzeug_zeichnen, werkzeug_molmasse, werkzeug_ionengruppe
        case quiz
    }
}

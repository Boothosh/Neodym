//
//  iPadOSMain.swift
//  Neodym
//
//  Created by Max Eckstein on 14.07.23.
//

import SwiftUI

struct iPadOSMain: View {
    
    @Binding var elementeManager: ElementManager
    @State private var ausgewaelterAppBereich: String? = "Elemente"
    @State private var systemIstAusgewaelt = true
    
    @State private var suchBegriff: String = ""
    @State private var ausgewaeltesElement: Element? = nil
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var sideBar: some View {
        List(selection: $ausgewaelterAppBereich){
            Label("Elemente", systemImage: "square.grid.4x3.fill")
                .tag("Elemente")
            Label("Wissen", systemImage: "graduationcap")
                .tag("Wissen")
            Label("Werkzeuge", systemImage: "wrench.and.screwdriver")
                .tag("Werkzeuge")
            Label("Quiz", systemImage: "brain")
                .tag("Quiz")
            Label("Einstellungen", systemImage: "gearshape.2")
                .tag("Einstellungen")
        }.navigationTitle("Neodym")
    }
    
    var hauptcontent: some View {
        NavigationStack {
            switch ausgewaelterAppBereich {
                case "Elemente":
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
                case "Wissen":
                    Wissen()
                case "Werkzeuge":
                    Werkzeuge(elementeManager: $elementeManager)
                case "Quiz":
                    QuizView()
                case "Einstellungen":
                    Einstellungen()
                default:
                    Text("Wähle einen Bereich der App aus, den du nutzen möchtest!")
            }
        }
    }
    
    var body: some View {
        if ausgewaelterAppBereich == "Elemente" && !systemIstAusgewaelt {
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
}

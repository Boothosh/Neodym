//
//  QuizSeitenView.swift
//  Neodym
//
//  Created by Max Eckstein on 07.11.23.
//

import SwiftUI

struct QuizSeitenView: View {
    
    @Environment(\.dismiss) var schließen
    @State var seitenIndex = -1
    @State var loesungAnzeigen = false
    @State var beantworteteFragen: [Int: Bool] = [:]
    @State var ausgewaelteAntworten: [String] = []
    @State var bounceEffekt = 0
    var seite: QuizSeite {
        quiz.inhalt[seitenIndex]
    }
    @Binding var quiz: Quiz
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                if seitenIndex < quiz.inhalt.count {
                    HStack {
                        Button(action: {
                            schließen()
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .foregroundStyle(.white, .red)
                                .frame(width: 75, height: 75)
                        })
                        .keyboardShortcut(.cancelAction)
                        Spacer()
                    }.padding()
                }
                if seitenIndex == -1 {
                    // Startseite
                    VStack {
                        Spacer()
                        GeometryReader { geo in
                            VStack(alignment: .leading, spacing: 0){
                                HStack(spacing: 0){
                                    HStack {
                                        Text(quiz.titel)
                                            .font(.title2)
                                            .padding(.leading)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }.frame(width: geo.size.width / 2)
                                    Image(quiz.bildName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }.frame(height: 4 * (geo.size.height / 5))
                                    .clipped()
                                HStack(spacing: 0){
                                    HStack {
                                        Text(quiz.schwierigkeit.rawValue)
                                            .padding(.leading)
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                        Spacer()
                                    }
                                        .frame(height: geo.size.height / 5)
                                        .background(quiz.schwierigkeit == .einfach ? .green : quiz.schwierigkeit == .mittel ? .orange : .red)
                                    Text("\(quiz.fortschritt)%")
                                        .frame(width: geo.size.width / 4)
                                }
                            }.background()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 25.0))
                        .modifier(Begrenzung())
                        .frame(width: 350, height: 350/1.75)
                        Button(action: {
                            seitenIndex += 1
                        }, label: {
                            HStack {
                                Spacer()
                                Text("Starten")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .frame(maxWidth: 350, minHeight: 45)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }).keyboardShortcut(.defaultAction)
                        .padding()
                        Spacer()
                    }
                } else if seitenIndex < quiz.inhalt.count {
                    // QuizSeite
                    VStack {
                        Spacer()
                        if loesungAnzeigen {
                            let richtig = ausgewaelteAntworten.sorted() == seite.richtigeAnworten.sorted()
                            VStack {
                                Text(richtig ? "Richtig" : "Falsch")
                                    .font(.largeTitle)
                                    .fontWeight(.black)
                                    .foregroundStyle(.white)
                                Image(systemName: richtig ? "checkmark.seal.fill" : "xmark.seal.fill")
                                    .resizable()
                                    .foregroundStyle(.white, richtig ? .green : .red)
                                    .frame(width: 150, height: 150)
                                    .symbolEffect(.bounce.up, options: .speed(0.75), value: bounceEffekt)
                                    .onAppear {
                                        bounceEffekt += 1
                                    }
                            }.frame(width: 400, height: 300)
                            .background(richtig ? .green.opacity(0.5) : .red.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 25.0))
                            .modifier(Begrenzung())
                        } else {
                            VStack(spacing: 50){
                                Text(seite.frage)
                                    .font(.title)
                                    .frame(width: 500)
                                    .multilineTextAlignment(.center)
                                LazyVGrid(columns: [GridItem(.fixed(300), spacing: 25), GridItem(.fixed(300), spacing: 25)], spacing: 25, content: {
                                    ForEach(seite.anwortMoeglichkeiten, id: \.self) { antwort in
                                        Button(action: {
                                            withAnimation {
                                                if ausgewaelteAntworten.contains(antwort) {
                                                    ausgewaelteAntworten.removeAll(where: {$0 == antwort})
                                                } else {
                                                    ausgewaelteAntworten.append(antwort)
                                                }
                                            }
                                        }, label: {
                                            Text(antwort)
                                                .frame(width: 300, height: 100)
                                                .background(ausgewaelteAntworten.contains(antwort) ? Color.green.opacity(0.5) : Color(uiColor: .systemBackground))
                                                .cornerRadius(25)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 25.0)
                                                        .stroke(ausgewaelteAntworten.contains(antwort) ? .green : .primary, lineWidth: 1)
                                                )
                                        })
                                    }
                                })
                            }
                        }
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                if loesungAnzeigen {
                                    ausgewaelteAntworten = []
                                    seitenIndex += 1
                                    loesungAnzeigen = false
                                } else {
                                    beantworteteFragen[seitenIndex] = ausgewaelteAntworten.sorted() == seite.richtigeAnworten.sorted()
                                    loesungAnzeigen = true
                                }
                            }
                        }, label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .resizable()
                                .foregroundStyle(.white, .blue)
                                .frame(width: 75, height: 75)
                        }).keyboardShortcut(.defaultAction)
                    }.padding()
                } else {
                    // Schluss Seite
                    let richtigeAnworten = beantworteteFragen.keys.filter({beantworteteFragen[$0]!}).count
                    let prozent = richtigeAnworten * 100 / beantworteteFragen.keys.count
                    HStack {
                        Spacer()
                        VStack(spacing: 0){
                            Spacer()
                            Image(systemName: "flag.checkered.2.crossed")
                                .foregroundStyle(.blue, .blue)
                                .font(.system(size: 60))
                            Text("Geschafft!")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .padding()
                            Text("Dein Ergebnis:")
                                .underline()
                                .padding()
                            Text("Du hattest \(richtigeAnworten) Fragen von insgesamt \(beantworteteFragen.keys.count) Fragen richtig, was \(prozent)% entspricht!")
                                .multilineTextAlignment(.center)
                            Button(action: {
                                UserDefaults.standard.setValue(prozent, forKey: quiz.titel)
                                quiz.fortschritt = prozent
                                schließen()
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("Schließen")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                                .frame(minHeight: 45)
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            })
                            .keyboardShortcut(.defaultAction)
                            .padding()
                            Spacer()
                        }.frame(maxWidth: 350)
                        Spacer()
                    }
                }
            }
        }
    }
}

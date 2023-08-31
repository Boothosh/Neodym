//
//  QuizView.swift
//  Neodym
//
//  Created by Max Eckstein on 13.07.23.
//

import SwiftUI

struct QuizView: View {
    @State var themen: [QuizThema] = [
        QuizThema(titel: "Säuren und Basen", quizes: [
            Quiz(titel: "Einstieg in Brønsted-Basen", fortschritt: 75, schwierigkeit: .einfach, bildName: "broensted", inhalt: [
                QuizSeite(frage: "Welche Aussage(n) trifft/treffen auf eine Brønsted-Base zu?", anwortMoeglichkeiten: ["Sie gibt Protonen ab.", "Sie nimmt Elektronen auf.", "Sie nimmt Protonen auf.", "Sie gibt Elektronen ab."], richtigeAnworten: ["Sie nimmt Protonen auf."]),
                QuizSeite(frage: "Wobei handelt es sich um eine Brønsted-Base?", anwortMoeglichkeiten: ["CO2", "NH3", "NaOH-", "H3O+"], richtigeAnworten: ["NH3", "NaOH-"])
            ]),
            Quiz(titel: "Einstieg in Brønsted-Säuren", fortschritt: 50, schwierigkeit: .mittel, bildName: "broensted", inhalt: []),
            Quiz(titel: "Ionenprodukt des Wassers", fortschritt: 78, schwierigkeit: .schwierig, bildName: "wasser", inhalt: []),
        ])
    ]
    @State var ausgewaeltesQuiz: Quiz? = nil
    
    let gridItems = [
        GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 30)
    ]
        
    func kachel(_ quiz: Quiz) -> some View {
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
            .aspectRatio(1.75, contentMode: .fill)
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                Image(.quizHintergundStreifen)
                    .resizable()
                    .frame(width: geo.size.width)
                    .aspectRatio(10, contentMode: .fit)
                ForEach(themen) { thema in
                    VStack{
                        HStack{
                            Text(thema.titel)
                                .fontWeight(.bold)
                            Spacer()
                        }.padding(.horizontal)
                        Color.primary
                            .frame(height: 2)
                            .padding(.horizontal)
                    }.padding(.vertical)
                    LazyVGrid(columns: gridItems, alignment: .leading, spacing: 30) {
                        ForEach(thema.quizes) { quiz in
                            kachel(quiz)
                                .onTapGesture {
                                    ausgewaeltesQuiz = quiz
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
                // Spacer
                HStack {}
                    .frame(height: 25)
            }
        }
        .edgesIgnoringSafeArea(.horizontal)
        .navigationTitle("Quiz")
        .toolbarBackground(Color("quizBg"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: $ausgewaeltesQuiz) { quiz in
            QuizSeitenView(quiz: quiz)
        }
    }
}

struct Begrenzung: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        if colorScheme != .dark {
            content
                .shadow(radius: 10)
        } else {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 25.0)
                        .stroke(.white, lineWidth: 1)
                )
        }
    }
}

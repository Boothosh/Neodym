//
//  QuizView.swift
//  Neodym
//
//  Created by Max Eckstein on 13.07.23.
//

import SwiftUI
import FirebaseRemoteConfig

struct QuizView: View {
    
    var remoteConfig = RemoteConfig.remoteConfig()
    
    @State var themen: [QuizThema] = []
    
    @State var ausgewaeltesQuiz: Quiz? = nil
    @State var themenIndex = 0
    @State var quizIndex = 0
    
    let gridItems = [
        GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 30)
    ]
    
    private func ladeRemoteConfig() async {
#if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
#endif
        remoteConfig.setDefaults(fromPlist: "remote_config_defaults")
        do {
            try await remoteConfig.activate()
            self.themen = try JSONDecoder().decode([QuizThema].self, from: try JSONSerialization.data(withJSONObject: remoteConfig.configValue(forKey: "quizze").jsonValue as! NSArray, options: []))
            try await remoteConfig.fetch()
        } catch let error {
            print(error)
        }
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
                            QuizKachel(quiz: quiz)
                                .onTapGesture {
                                    for i in themen.enumerated() {
                                        for j in i.element.quizes.enumerated() {
                                            if j.element == quiz {
                                                themenIndex = i.offset
                                                quizIndex = j.offset
                                            }
                                        }
                                    }
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
            QuizSeitenView(quiz: $themen[themenIndex].quizes[quizIndex])
        }
        .task {
            await ladeRemoteConfig()
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

struct QuizKachel: View {
    
    let quiz: Quiz
    @State var bild: UIImage?
    
    var body: some View {
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
                    if let bild {
                        Image(uiImage: bild)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }.frame(height: 4 * (geo.size.height / 5))
                    .clipped()
                HStack(spacing: 0){
                    HStack {
                        Text(quiz.schwierigkeit.rawValue.capitalized)
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
        .task {
            bild = await StorageManager.quizBild(quizName: quiz.titel, bildID: quiz.bildID)
        }
    }
    
}

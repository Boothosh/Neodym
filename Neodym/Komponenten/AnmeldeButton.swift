//
//  AnmeldeButton.swift
//  Neodym
//
//  Created by Max Eckstein on 15.03.24.
//

import SwiftUI

struct AnmeldeButton: View {
    
    @Binding var laden: Bool
    let text: String
    let action: () -> ()
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack{
                Spacer()
                Text(text)
                    .foregroundColor(.black)
                    .font(.title3)
                Spacer()
                if !laden {
                    Image("")
                        .resizable()
                        .frame(width: 35, height:35)
                } else {
                    ProgressView()
                        .tint(.pink)
                        .frame(width: 35, height:35)
                }
            }
            .padding(.horizontal)
            .frame(height: 60)
            .background(.white)
            .cornerRadius(15)
            .shadow(radius: 7)
        }
    }
}

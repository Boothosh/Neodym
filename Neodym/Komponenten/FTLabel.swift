//
//  FTLabel.swift
//  Neodym
//
//  Created by Max Eckstein on 30.03.24.
//

import SwiftUI

struct FTLabel: View {
    let text: String
    let bild: String
    let scale: Double
    let size: CGFloat?
    init(_ text: String, bild: String, scale: Double = 1.0, size: CGFloat? = nil) {
        self.text = text
        self.bild = bild
        self.scale = scale
        self.size = size
    }
    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(bild)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(CGSize(width: scale, height: scale))
                .frame(width: size, height: size)
        }
    }
}

//
//  CustomTextFeld.swift
//  Neodym
//
//  Created by Max Eckstein on 15.03.24.
//

import SwiftUI

struct CustomTextFeld: ViewModifier {
    
    @Environment(\.colorScheme) private var colorScheme
    @Binding var error: Bool
    
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
#if os(iOS) || os(visionOS)
            .textInputAutocapitalization(.never)
#endif
            .autocorrectionDisabled()
            .padding(.horizontal, 30)
            .frame(height: 60)
            .background(colorScheme == .dark ? Color.init(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.7) : .white)
            .cornerRadius(15)
            .overlay(error ? RoundedRectangle(cornerRadius: 15).stroke(.red, lineWidth: 1) : nil)
            .shadow(radius: 7)
    }
}

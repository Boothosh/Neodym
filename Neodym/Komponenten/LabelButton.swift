//
//  LabelButton.swift
//  Neodym
//
//  Created by Max Eckstein on 31.12.23.
//

import SwiftUI

struct LabelButton: View {
    
    let text: String
    let symbol: String
    let action: () async -> ()
    var role: ButtonRole? = nil
    
    @State private var progress = false
    
    var body: some View {
        Button(role: role) {
            Task {
                progress = true
                Task.detached(priority: .userInitiated) {
                    await self.action()
                    self.progress = false
                }
            }
        } label: {
            Label {
                Text(text)
            } icon: {
                if !progress {
                    Image(systemName: symbol)
                        .foregroundStyle(role == .destructive ? .red : .accent)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.pink)
                }
            }
        }
    }
}

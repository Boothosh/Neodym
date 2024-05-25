//
//  PlatformImage.swift
//  Neodym
//
//  Created by Max Eckstein on 23.04.24.
//

import Foundation

#if canImport(UIKit)

import UIKit
extension UIImage: PlatformImage {}

#elseif canImport(AppKit)

import AppKit
extension NSImage: PlatformImage {}

#endif

protocol PlatformImage {}

struct CrossPlatformImage {
    let image: any PlatformImage
    init?(data: Data) {
#if canImport(UIKit)
        guard let i = UIImage(data: data) else { return nil}
        image = i
#elseif canImport(AppKit)
        guard let i = NSImage(data: data) else { return nil}
        image = i
#endif
    }
    init?(contentsOfFile file: String) {
#if canImport(UIKit)
        guard let i = UIImage(contentsOfFile: file) else { return nil}
        image = i
#elseif canImport(AppKit)
        guard let i = NSImage(contentsOfFile: file) else { return nil}
        image = i
#endif
    }
}

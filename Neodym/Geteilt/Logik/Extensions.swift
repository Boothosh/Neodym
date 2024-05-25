//
//  Extensions.swift
//  Neodym
//
//  Created by Max Eckstein on 12.02.24.
//

import SwiftUI

extension String {
    var ohneUmlaute: String {
        self.replacing("ä", with: "ae").replacing("ü", with: "ue").replacing("ö", with: "oe")
    }
}

/// Quelle: https://stackoverflow.com/questions/36068104/convert-integer-to-roman-numeral-string-in-swift, Brian Sachetta, Editiert
extension Int {
    var roemisch: String? {
        var integerValue = abs(self)
        if integerValue >= 4000 || integerValue == 0 {
            // Nicht darstellbar
            return nil
        }
        var numeralString = self > 0 ? "+" : "-"
        let mappingList: [(Int, String)] = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"), (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        for i in mappingList {
            while (integerValue >= i.0) {
                integerValue -= i.0
                numeralString += i.1
            }
        }
        return numeralString
    }
}

extension CGPoint {
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

extension Int {
    var formatiertAlsLadung: String {
        if self > 0 {
            return self.description + "+"
        } else if self < 0 {
            return abs(self).description + "-"
        } else {
            return self.description
        }
    }
}

//
//  Temperatur.swift
//  Neodym
//
//  Created by Max Eckstein on 09.09.23.
//

import Foundation

struct Temperatur: Equatable {
    
    let kelvin: Float
    let fahrenheit: Float
    let celsius: Float
    
    init(k kelvin: Float) {
        self.kelvin = kelvin
        self.fahrenheit = (kelvin - 273.15) * 9/5 + 32
        self.celsius = kelvin - 273.15
    }
    
    init(gC celsius: Float) {
        self.kelvin = celsius + 273.15
        self.fahrenheit = celsius * 9/5 + 32
        self.celsius = celsius
    }
    
    init(gF fahrenheit: Float) {
        self.kelvin = fahrenheit * 5/9 - 32 + 273.15
        self.fahrenheit = fahrenheit
        self.celsius = fahrenheit * 5/9 - 32
    }
    
    static func < (lhs: Temperatur, rhs: Temperatur) -> Bool {
        return lhs.kelvin < rhs.kelvin
    }
    
    var formatiert: String {
        guard let nutzerPraeferenz = UserDefaults.standard.string(forKey: "temperaturFormat") else {
            return String(format: "%.2f K", self.kelvin)
        }
        if nutzerPraeferenz == "kelvin" {
            return String(format: "%.2f K", self.kelvin)
        } else if nutzerPraeferenz == "celsius" {
            return String(format: "%.2f °C", self.celsius)
        } else if nutzerPraeferenz == "fahrenheit" {
            return String(format: "%.2f °F", self.fahrenheit)
        } else {
            print("Präferiertes Temperaturformat existiert nicht")
            return "Fehler"
        }
    }
    
    static var standard: Temperatur { return Temperatur(gC: 25) }
}

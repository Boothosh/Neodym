//
//  Vektor.swift
//  Neodym
//
//  Created by Max Eckstein on 09.06.23.
//

import SwiftUI

struct Vektor {
    
    var x: CGFloat
    var y: CGFloat
    
    init (vom punkt1: CGPoint, zum punkt2: CGPoint) {
        self.x = punkt2.x - punkt1.x
        self.y = punkt2.y - punkt1.y
    }
    
    func winkel() -> Angle {
        var winkel = -atan(-y/x) + .pi / 2
        // +.pi/2 da bei einem für eine paralele zur x-Achse, also einem Winkel a = 0, um 90° oder .pi/2 gedreht werden muss
        if x >= 0 {
            // Der Tangens deckt nur den Bereich zwischen 0 und 180° ab.
            // Da allerdings relevant ist ob die Verbindung grade nach vorne oder hinten zeigt,
            // muss Pi addiert werden, wenn sich der Vektor im 2. oder 3. Quadranten befindet
            winkel += .pi
        }
        return Angle(radians: winkel)
    }

}

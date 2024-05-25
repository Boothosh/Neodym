//
//  AppBereiche.swift
//  Neodym
//
//  Created by Max Eckstein on 02.05.24.
//

import Foundation

enum SideBarAppBereich: Hashable {
    case elemente
    case lizenzen
    case quiz
    
    // Wissen
    case stoechometrie
    case molekuele
    
    // Werkzeuge
    case canvas
    case molmasse
    case ionengruppe
}

enum TabAppBereich: Hashable {
    case elemente
    case wissen
    case werkzeuge
    case quiz
    case lizenzen
    case einstellungen
}

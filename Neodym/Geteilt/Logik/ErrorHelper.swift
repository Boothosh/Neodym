//
//  ErrorHelper.swift
//  Neodym
//
//  Created by Max Eckstein on 01.10.23.
//

import Foundation

struct ErrorHelper {
    
    // Error der dem Benutzer angezeigt werden kann
    struct BenutzerError: Error {
        let titel: String
        let nachricht: String
    }
    
    // Error, der nicht dafür konzipiert ist dem Benutzer angezeigt zu werden
    struct InternerError: Error {
        let debugInfos: String?
    }
}

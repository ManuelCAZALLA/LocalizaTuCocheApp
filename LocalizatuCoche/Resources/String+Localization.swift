//
//  String+Localization.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 22/6/25.
//

import Foundation
import SwiftUI

extension String {
    
    /// Returns a localized version of the string
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns a localized version of the string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    /// Returns a localized version of the string with format arguments
    func localized(with arguments: [CVarArg]) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    /// Returns localized or a provided fallback if missing
    func localizedOr(_ fallback: String) -> String {
        let value = NSLocalizedString(self, comment: "")
        if value == self { return fallback }
        return value
    }
} 
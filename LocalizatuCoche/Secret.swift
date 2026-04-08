// Secret.swift
// Acceso seguro a claves secretas desde Info.plist

import Foundation

struct Secret {
    static var revenueCatAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String, !key.isEmpty else {
            fatalError("RevenueCatAPIKey no está definida en Info.plist o está vacía.")
        }
        return key
    }
}

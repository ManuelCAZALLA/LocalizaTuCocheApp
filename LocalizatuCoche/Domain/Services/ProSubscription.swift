import Foundation
import RevenueCat

enum Entitlement {
    /// Identificador principal en RevenueCat (ajusta si en el dashboard usas otro).
    static let premium = "Premium"
    static let premiumAlternate = "premium"

    static func isPremiumActive(in customerInfo: CustomerInfo) -> Bool {
        customerInfo.entitlements[premium]?.isActive == true
            || customerInfo.entitlements[premiumAlternate]?.isActive == true
    }

    static var isProUser: Bool {
        UserDefaults.standard.bool(forKey: "isPro")
    }
}

enum ProFeatureLimits {
    static let freeHistoryCount = 3
    static let freeParkingMeterMaxMinutes = 60
    static let launchPaywallCooldownDays = 3
}

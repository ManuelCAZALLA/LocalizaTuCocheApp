import Foundation
import SwiftUI
import AppTrackingTransparency
import AdSupport

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

final class AdsService {
    static let shared = AdsService()
    private init() {}
    
    @AppStorage("isPro") private var isPro: Bool = false
    
    func start() {
        guard !isPro else { return }
#if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
#endif
        requestTrackingAuthorizationIfNeeded()
    }
    
    private func requestTrackingAuthorizationIfNeeded() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}






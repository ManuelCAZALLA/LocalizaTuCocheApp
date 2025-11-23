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
    
    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    private var interstitialDelegate: InterstitialDelegate?
    #endif
    
    func start() {
        guard !isPro else { return }
#if canImport(GoogleMobileAds)
        MobileAds.shared.start(completionHandler: nil)
        loadInterstitialAd()
#endif
        requestTrackingAuthorizationIfNeeded()
    }
    
    #if canImport(GoogleMobileAds)
    func loadInterstitialAd() {
        let request = Request()
        InterstitialAd.load(with: "ca-app-pub-3940256099942544/4411468910", request: request) { [weak self] ad, error in
            if let ad = ad {
                self?.interstitial = ad
            } else {
                self?.interstitial = nil
                print("Failed to load interstitial ad: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    func showInterstitial(from root: UIViewController, completion: @escaping () -> Void) {
        guard let ad = interstitial else {
            completion()
            loadInterstitialAd()
            return
        }
        ad.present(from: root)
        let delegate = InterstitialDelegate(onDismiss: { [weak self] in
            self?.interstitial = nil
            self?.interstitialDelegate = nil
            self?.loadInterstitialAd()
            completion()
        })
        self.interstitialDelegate = delegate
        ad.fullScreenContentDelegate = delegate
    }
    #endif
    
    private func requestTrackingAuthorizationIfNeeded() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}

#if canImport(GoogleMobileAds)
private class InterstitialDelegate: NSObject, FullScreenContentDelegate {
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { onDismiss() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { onDismiss() }
}
#endif

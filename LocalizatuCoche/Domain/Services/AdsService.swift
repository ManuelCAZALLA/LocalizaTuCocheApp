import Foundation
import SwiftUI
// import AppTrackingTransparency  // Comentado: no se usa tracking en esta versión
// import AdSupport  // Comentado: no se usa tracking en esta versión
import GoogleMobileAds


final class AdsService {
    static let shared = AdsService()
    private init() {}
    
    @AppStorage("isPro") private var isPro: Bool = false
    
    private var interstitial: InterstitialAd?
    private var interstitialDelegate: InterstitialDelegate?
    
    func start() {
        guard !isPro else { return }

        MobileAds.shared.start(completionHandler: nil)
        loadInterstitialAd()

        // requestTrackingAuthorizationIfNeeded()  // Comentado: no se usa tracking en esta versión
    }
    
    
    func loadInterstitialAd() {
        let request = Request()
        guard let unitID = Bundle.main.infoDictionary?["GOOGLE_ADS_UNIT_ID"] as? String else {
            print("No se encontró GOOGLE_ADS_UNIT_ID en Info.plist")
            return
        }
        InterstitialAd.load(with: unitID, request: request) { [weak self] ad, error in
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

    
    // Comentado: no se usa tracking en esta versión
    // private func requestTrackingAuthorizationIfNeeded() {
    //     if #available(iOS 14, *) {
    //         ATTrackingManager.requestTrackingAuthorization { _ in }
    //     }
    // }
}


private class InterstitialDelegate: NSObject, FullScreenContentDelegate {
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { onDismiss() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { onDismiss() }
}



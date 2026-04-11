import Foundation
import UIKit
import AppTrackingTransparency
import AdSupport
import GoogleMobileAds


final class AdsService {
    static let shared = AdsService()
    private init() {}

    /// Mismo key que `@AppStorage("isPro")` en SwiftUI. Leer siempre desde UserDefaults (no usar `@AppStorage` en esta clase: el orden con RevenueCat y el singleton pueden dejar anuncios sin cargar).
    private var isProSubscriber: Bool {
        UserDefaults.standard.bool(forKey: "isPro")
    }

    private var interstitial: InterstitialAd?
    private var interstitialDelegate: InterstitialDelegate?
    
    func start() {
        guard !isProSubscriber else { return }

        MobileAds.shared.start(completionHandler: nil)
        loadInterstitialAd()

        requestTrackingAuthorizationIfNeeded()
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
        guard !isProSubscriber else {
            completion()
            return
        }
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

    /// Versión de conveniencia para SwiftUI: busca el topViewController automáticamente.
    func showInterstitial(completion: @escaping () -> Void) {
        guard !isProSubscriber else {
            completion()
            return
        }
        // No mostrar en previews de Xcode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            completion()
            return
        }
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            completion()
            return
        }
        showInterstitial(from: rootVC, completion: completion)
    }

    
    private func requestTrackingAuthorizationIfNeeded() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}


private class InterstitialDelegate: NSObject, FullScreenContentDelegate {
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { onDismiss() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { onDismiss() }
}



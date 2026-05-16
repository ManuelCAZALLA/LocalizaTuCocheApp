import Foundation
import UIKit
import AppTrackingTransparency
import AdSupport
import GoogleMobileAds

// MARK: - Top VC helper

private extension UIViewController {
    var ltc_topMostViewController: UIViewController {
        if let presented = presentedViewController {
            return presented.ltc_topMostViewController
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.ltc_topMostViewController ?? nav
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.ltc_topMostViewController ?? tab
        }
        return self
    }
}

// MARK: - AdsService

final class AdsService {
    static let shared = AdsService()
    private init() {}

    private var isProSubscriber: Bool {
        UserDefaults.standard.bool(forKey: "isPro")
    }

    private var interstitial: InterstitialAd?
    private var interstitialDelegate: InterstitialDelegate?
    private var isLoading = false

    /// True cuando hay un anuncio listo para presentar
    var isAdReady: Bool { interstitial != nil }

    // MARK: - Start

    func start() {
        guard !isProSubscriber else { return }
        MobileAds.shared.start(completionHandler: nil)
        loadInterstitialAd()
        requestTrackingAuthorizationIfNeeded()
    }

    // MARK: - Load

    func loadInterstitialAd() {
        guard !isProSubscriber else { return }
        guard interstitial == nil, !isLoading else { return }
        guard let unitID = Bundle.main.infoDictionary?["GOOGLE_ADS_UNIT_ID"] as? String else { return }

        isLoading = true
        let request = Request()
        InterstitialAd.load(with: unitID, request: request) { [weak self] ad, _ in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.interstitial = ad
            }
        }
    }

    // MARK: - Show

    func showInterstitial(completion: @escaping () -> Void) {
        guard !isProSubscriber else {
            completion()
            return
        }
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            completion()
            return
        }
        guard let rootVC = Self.resolveKeyWindowRootViewController() else {
            return
        }

        let presenter = rootVC.ltc_topMostViewController

        guard let ad = interstitial else {
            // Anuncio no disponible: muestra alert, NO llama completion ni abre el mapa
            loadInterstitialAd()
            let alert = UIAlertController(
                title: "pro_gate_ad_unavailable_title".localized,
                message: "pro_gate_ad_unavailable_message".localized,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "ok".localized, style: .default))
            if presenter.presentedViewController == nil {
                presenter.present(alert, animated: true)
            }
            return
        }

        // Delegate ANTES de present()
        let delegate = InterstitialDelegate(onDismiss: { [weak self] in
            self?.interstitial = nil
            self?.interstitialDelegate = nil
            self?.loadInterstitialAd()
            completion()
        })
        self.interstitialDelegate = delegate
        ad.fullScreenContentDelegate = delegate
        ad.present(from: presenter)
    }

    // MARK: - Root ViewController

    private static func resolveKeyWindowRootViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes where scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive {
            if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                return root
            }
            if let root = scene.windows.first?.rootViewController {
                return root
            }
        }
        return scenes.first?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scenes.first?.windows.first?.rootViewController
    }

    // MARK: - Tracking

    private func requestTrackingAuthorizationIfNeeded() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}

// MARK: - Delegate

private class InterstitialDelegate: NSObject, FullScreenContentDelegate {
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onDismiss()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onDismiss()
    }
}

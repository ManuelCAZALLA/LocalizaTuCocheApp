import Foundation
import GoogleMobileAds
import UIKit

final class AdManager: NSObject, FullScreenContentDelegate {
    static let shared = AdManager()
    private var interstitial: InterstitialAd?
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910" // ID de prueba de Google
    
    private override init() {
        super.init()
        // Añadir el dispositivo como test device para AdMob
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["a511307cec47da31400033582f692c19"]
        loadInterstitial()
    }
    
    func loadInterstitial() {
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Error cargando interstitial: \(error.localizedDescription)")
                self?.interstitial = nil
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }
    
    func showInterstitial(from root: UIViewController) {
        guard let interstitial = interstitial else {
            print("Interstitial no listo")
            loadInterstitial()
            return
        }
        interstitial.present(from: root)
    }
    
    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        loadInterstitial() // Prepara el siguiente anuncio
    }
} 

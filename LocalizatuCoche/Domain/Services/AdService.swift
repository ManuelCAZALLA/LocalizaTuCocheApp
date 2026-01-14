import Foundation
import GoogleMobileAds
import UIKit

/// Servicio para gestionar anuncios de Google Ads
class AdService: NSObject, ObservableObject {
    static let shared = AdService()
    
    let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    private var interstitialAd: InterstitialAd?
    private var isLoadingAd = false
    var pendingCompletion: (() -> Void)?
    
    private override init() {
        super.init()
    }
    
    func initialize() {
        MobileAds.shared.start(completionHandler: nil)
    }
    
    func loadInterstitialAd() {
        guard interstitialAd == nil && !isLoadingAd else { return }
        
        isLoadingAd = true
        
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoadingAd = false
                
                if let error = error {
                    print("Error cargando anuncio: \(error.localizedDescription)")
                    return
                }
                
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    func showInterstitialAd(completion: @escaping () -> Void) {
        guard let ad = interstitialAd else {
            loadInterstitialAd()
            completion()
            return
        }
        
        var rootViewController: UIViewController?
        if #available(iOS 15.0, *) {
            rootViewController = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
        } else {
            rootViewController = UIApplication.shared.windows.first?.rootViewController
        }
        
        guard let rootVC = rootViewController else {
            completion()
            return
        }
        
        // Guardar el completion para llamarlo cuando el anuncio se cierre
        pendingCompletion = completion
        
        ad.present(from: rootVC)
        interstitialAd = nil
        loadInterstitialAd()
    }
    
    var hasAdReady: Bool {
        return interstitialAd != nil
    }
}


//
//  Extension+AdService.swift
//  LocalizatuCoche
//
//  Created by Manuel Cazalla Colmenero
//

import Foundation
import GoogleMobileAds

extension AdService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Cuando el anuncio se cierra, llamar al completion pendiente
        if let completion = pendingCompletion {
            DispatchQueue.main.async {
                completion()
            }
            pendingCompletion = nil
        }
        loadInterstitialAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Error mostrando anuncio: \(error.localizedDescription)")
        // Si falla al mostrar, llamar al completion de todas formas
        if let completion = pendingCompletion {
            DispatchQueue.main.async {
                completion()
            }
            pendingCompletion = nil
        }
        loadInterstitialAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Anuncio se está mostrando
    }
}

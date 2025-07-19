import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private let appStoreURL = URL(string: "https://apps.apple.com/app/idTU_ID_DE_APP")! // REEMPLAZA ESTE ENLACE POR EL REAL CUANDO LA APP ESTÉ PUBLICADA
    
    init() {}
    
    func shareOnWhatsApp() {
        let message = "¡Descarga UbicaTuCar! " + appStoreURL.absoluteString
        let urlString = "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Si WhatsApp no está instalado, puedes mostrar un alert o usar UIActivityViewController
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://tuapp.com/politica-privacidad") {
            UIApplication.shared.open(url)
        }
    }
    
    func contactSupport() {
        let email = "soporte@tuapp.com"
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
} 
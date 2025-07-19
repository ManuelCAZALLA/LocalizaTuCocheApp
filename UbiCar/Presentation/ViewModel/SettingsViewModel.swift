import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var adsRemoved: Bool {
        didSet { UserDefaults.standard.set(adsRemoved, forKey: "settings_adsRemoved") }
    }
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    init() {
        self.adsRemoved = false // No hay anuncios en la primera versión
    }
    
    func shareOnWhatsApp() {
        let message = "¡Descarga UbicaTuCar! https://tuapp.com"
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
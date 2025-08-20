import SwiftUI
import StoreKit
import MessageUI

class SettingsViewModel: ObservableObject {
    // MARK: - Published
    @Published var showEmailAlert = false
    @Published var showMailComposer = false
    @Published var showShareSheet = false
    @Published var shareItems: [Any] = []
    
    // MARK: - App Info
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.1"
    }
    
    // MARK: - URLs y datos de soporte
    let appStoreURL = URL(string: "https://apps.apple.com/app/id6749463931")!
    let privacyPolicyURL = URL(string: "https://manuelcazalla.github.io/LocalizatuCoche-Web/Politica-Privacidad.html")!
    let supportEmail = "soportecazalla@gmail.com"
    let websiteURL = URL(string: "https://manuelcazalla.github.io/LocalizatuCoche-Web/")!
    
    // MARK: - Compartir en WhatsApp o fallback
    func shareOnWhatsApp() {
        let message = "¡Descarga Localiza tu Coche! \(appStoreURL.absoluteString)"
        let urlString = "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // WhatsApp no instalado, usar UIActivityViewController
            shareItems = [message]
            showShareSheet = true
        }
    }
    
    // MARK: - Abrir Política de Privacidad
    func openPrivacyPolicy() {
        UIApplication.shared.open(privacyPolicyURL, options: [:], completionHandler: nil)
    }
    
    // MARK: - Contactar Soporte
    func contactSupport() {
        if let url = URL(string: "mailto:\(supportEmail)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            showEmailOptions()
        }
    }
    
    private func showEmailOptions() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            showEmailAlert = true
        }
    }
    
    // MARK: - Abrir web
    func openWebsite() {
        UIApplication.shared.open(websiteURL, options: [:], completionHandler: nil)
    }
    
    // MARK: - Abrir valoración en App Store
    func requestReview() {
        // URL que lleva directamente a la App Store para valorar
        let reviewURL = URL(string: "https://apps.apple.com/app/id6749463931?action=write-review")!
        UIApplication.shared.open(reviewURL, options: [:], completionHandler: nil)
    }
    
    // MARK: - Copiar email al portapapeles
    func copyEmailToClipboard() {
        UIPasteboard.general.string = supportEmail
    }
    
    // MARK: - Compartir email
    func shareEmail() -> String {
        return "Contacto de soporte: \(supportEmail)"
    }
}

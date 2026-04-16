import SwiftUI
import StoreKit
import MessageUI

class SettingsViewModel: ObservableObject {
    @Published var showEmailAlert = false
    @Published var showMailComposer = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private let appStoreURL = URL(string: "https://apps.apple.com/app/idTU_ID_DE_APP")! // Cambiar por URL real
    
    private let privacyPolicyURL = URL(string: "https://manuelcazalla.github.io/LocalizatuCoche-Web/Politica-Privacidad.html")!
    private let supportEmail = "soportecazalla@gmail.com"
    private let websiteURL = URL(string: "https://manuelcazalla.github.io/LocalizatuCoche-Web/")!
    
    init() {}
    
    func shareOnWhatsApp() {
        let message = "¡Descarga Tu Coche Aquí! " + appStoreURL.absoluteString
        let urlString = "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // WhatsApp no instalado, alternativa: mostrar alerta o UIActivityViewController
        }
    }
    
    func openPrivacyPolicy() {
        UIApplication.shared.open(privacyPolicyURL)
    }
    
    // VERSIÓN MEJORADA DEL CONTACT SUPPORT
    func contactSupport() {
        // Primero intentar abrir Mail app
        if let url = URL(string: "mailto:\(supportEmail)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Si Mail no está disponible, mostrar alternativas
            showEmailOptions()
        }
    }
    
    private func showEmailOptions() {
        // Intentar usar MFMailComposeViewController si está disponible
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Mostrar alert con opciones alternativas
            showEmailAlert = true
        }
    }
    
    func openWebsite() {
        UIApplication.shared.open(websiteURL)
    }
    
    @MainActor
    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
    
    // MÉTODO PARA COPIAR EMAIL AL PORTAPAPELES
    func copyEmailToClipboard() {
        UIPasteboard.general.string = supportEmail
    }
    
    // MÉTODO PARA COMPARTIR EMAIL
    func shareEmail() -> String {
        return "Contacto de soporte: \(supportEmail)"
    }
}

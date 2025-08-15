import SwiftUI
import StoreKit

struct RateOrRecommendPopup: View {
    @Binding var isPresented: Bool
    let onRatedOrRecommended: () -> Void
    
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6749463931")!
    
    var body: some View {
        EmptyView()
            .alert("rate_or_recommend_message".localized, isPresented: $isPresented) {
                Button("rate_app".localized) {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                    UserDefaults.standard.set(true, forKey: "hasRatedOrRecommended")
                    UserDefaults.standard.set(Date(), forKey: "lastRatePopupDate")
                    onRatedOrRecommended()
                }
                Button("recommend_friend".localized) {
                    let activityVC = UIActivityViewController(activityItems: [appStoreURL], applicationActivities: nil)
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = scene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true, completion: nil)
                    }
                    UserDefaults.standard.set(true, forKey: "hasRatedOrRecommended")
                    UserDefaults.standard.set(Date(), forKey: "lastRatePopupDate")
                    onRatedOrRecommended()
                }
                Button("not_now".localized, role: .cancel) { }
            } message: {
                Text("rate_or_recommend_message".localized)
            }
    }
}

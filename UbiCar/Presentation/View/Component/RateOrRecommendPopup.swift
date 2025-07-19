import SwiftUI
import StoreKit

struct RateOrRecommendPopup: View {
    @Binding var isPresented: Bool
    let onRatedOrRecommended: () -> Void
    
    var body: some View {
        EmptyView()
            .alert("rate_or_recommend_message".localized, isPresented: $isPresented) {
                Button("rate_app".localized) {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        if #available(iOS 18.0, *) {
                            AppStore.requestReview(in: scene)
                        } else {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }
                    UserDefaults.standard.set(true, forKey: "hasRatedOrRecommended")
                    UserDefaults.standard.set(Date(), forKey: "lastRatePopupDate")
                    onRatedOrRecommended()
                }
                Button("recommend_friend".localized) {
                    let url = URL(string: "https://apps.apple.com/app/idTU_ID_DE_APP")!
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
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

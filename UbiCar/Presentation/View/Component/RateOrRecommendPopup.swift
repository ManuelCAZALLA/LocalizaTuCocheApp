import SwiftUI
import StoreKit

struct RateOrRecommendPopup: View {
    @Binding var isPresented: Bool
    let onRatedOrRecommended: () -> Void
    
    var body: some View {
        EmptyView()
            .alert("¿Te gusta UbicTuCar?", isPresented: $isPresented) {
                Button("Valorar la app") {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        if #available(iOS 18.0, *) {
                            AppStore.requestReview(in: scene)
                        } else {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    }
                    UserDefaults.standard.set(true, forKey: "hasRatedOrRecommended")
                    onRatedOrRecommended()
                }
                Button("Recomendar a un amigo") {
                    let url = URL(string: "https://apps.apple.com/app/idTU_ID_DE_APP")!
                    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = scene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true, completion: nil)
                    }
                    UserDefaults.standard.set(true, forKey: "hasRatedOrRecommended")
                    onRatedOrRecommended()
                }
                Button("Ahora no", role: .cancel) { }
            } message: {
                Text("Si te resulta útil, ¡valóranos o recomiéndanos a un amigo! 🚗✨")
            }
    }
}

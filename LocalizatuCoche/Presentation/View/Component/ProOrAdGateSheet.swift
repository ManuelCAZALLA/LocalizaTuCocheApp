import SwiftUI

/// Hoja intermedia antes de un intersticial: ofrece pasar a Pro (paywall en el padre) o ver anuncio.
struct ProOrAdGateSheet: View {
    let title: String
    let message: String
    var gateCompleted: Binding<Bool>? = nil
    let onUpgrade: () -> Void
    let onWatchAd: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// Refresca la UI cada 0.5s para detectar cuando el anuncio está listo
    @State private var adReady: Bool = AdsService.shared.isAdReady
    @State private var adCheckTimer: Timer? = nil

    private static let postDismissDelayUpgrade: TimeInterval = 0.35
    private static let postDismissDelayWatchAd: TimeInterval = 1.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AccentColor"), Color("AppPrimary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 4)

                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 12) {
                    // Botón Pro
                    Button {
                        gateCompleted?.wrappedValue = true
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + Self.postDismissDelayUpgrade) {
                            onUpgrade()
                        }
                    } label: {
                        Text("pro_cta_button".localized)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(
                                LinearGradient(
                                    colors: [Color("AccentColor"), Color("AppPrimary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    // Botón Ver Anuncio — muestra spinner si el anuncio no está listo
                    Button {
                        guard adReady else { return }
                        gateCompleted?.wrappedValue = true
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + Self.postDismissDelayWatchAd) {
                            onWatchAd()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if !adReady {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("pro_gate_ad_loading".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            } else {
                                Text("pro_gate_watch_ad".localized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!adReady)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            adReady = AdsService.shared.isAdReady
            if !adReady {
                AdsService.shared.loadInterstitialAd()
                // Comprueba cada 0.5s si el anuncio ya está listo
                adCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    adReady = AdsService.shared.isAdReady
                    if adReady { adCheckTimer?.invalidate() }
                }
            }
        }
        .onDisappear {
            adCheckTimer?.invalidate()
            adCheckTimer = nil
        }
    }
}

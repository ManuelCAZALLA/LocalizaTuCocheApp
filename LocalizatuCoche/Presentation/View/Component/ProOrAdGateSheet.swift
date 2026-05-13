import SwiftUI

/// Hoja intermedia antes de un intersticial: ofrece pasar a Pro (paywall en el padre) o ver anuncio.
struct ProOrAdGateSheet: View {
    let title: String
    let message: String
    /// Si no es `nil`, se pone a `true` al elegir Pro o anuncio (para distinguir cancelación / swipe del sheet).
    var gateCompleted: Binding<Bool>? = nil
    let onUpgrade: () -> Void
    let onWatchAd: () -> Void

    @Environment(\.dismiss) private var dismiss

    private static let postDismissDelay: TimeInterval = 0.35

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
                    Button {
                        gateCompleted?.wrappedValue = true
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + Self.postDismissDelay) {
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

                    Button {
                        gateCompleted?.wrappedValue = true
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + Self.postDismissDelay) {
                            onWatchAd()
                        }
                    } label: {
                        Text("pro_gate_watch_ad".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

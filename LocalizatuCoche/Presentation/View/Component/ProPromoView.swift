import SwiftUI

struct ProPromoView: View {
    @AppStorage("isPro") private var isPro: Bool = false
    let onDismiss: () -> Void
    
    @State private var isVisible: Bool = false
    @State private var secondsLeft: Int = 5
    
    var body: some View {
        ZStack {
            // Fondo semitransparente o color base
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Spacer()
                    // Botón de cierre secundario, solo visible si el temporizador ha acabado
                    Button(action: dismiss) {
                        Text(
                            secondsLeft > 0
                            ? "close_countdown".localized(with: secondsLeft)
                            : "pro_close_button".localized
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(10)
                    }
                    .disabled(secondsLeft > 0)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Título principal con icono
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Color.yellow)
                                .font(.system(size: 40))
                            
                            Text("pro_promo_title".localized)
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .textCase(.uppercase)
                            
                            Text("pro_promo_subtitle".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // MARK: - Lista de Beneficios
                        VStack(alignment: .leading, spacing: 20) {
                            benefitRow(icon: "nosign", key: "pro_benefit_no_ads")
                            benefitRow(icon: "clock.badge.checkmark", key: "pro_benefit_unlimited_parkings")
                            benefitRow(icon: "moon.fill", key: "pro_benefit_dark_mode")
                            benefitRow(icon: "waveform.and.mic", key: "pro_benefit_siri")
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                }
                
                // MARK: - CTA Principal (Fijo en la parte inferior)
                Button(action: { isPro = true; dismiss() }) {
                    Text("pro_cta_button".localized)
                        .font(.headline)
                        .fontWeight(.heavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .buttonStyle(PlainButtonStyle())
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.98)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        }
        .onAppear {
            isVisible = true
            if isPro {
                dismiss()
                return
            }
            startCountdown()
        }
    }
    
    // MARK: - Fila de Beneficio con Estilo
    private func benefitRow(icon: String, key: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(Color.orange) // Color destacado
                .font(.title2)
                .frame(width: 30)
            
            Text(key.localized)
                .foregroundColor(.primary)
                .font(.body)
            
            Spacer()
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
    
    private func startCountdown() {
        secondsLeft = 5
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if secondsLeft > 0 {
                withAnimation { secondsLeft -= 1 }
            }
            if secondsLeft == 0 {
                timer.invalidate()
            }
        }
    }
}

#Preview("ProPromo Light") {
    ProPromoView(onDismiss: {
        print("ProPromoView dismissed")
    })
    .preferredColorScheme(.light)
}

#Preview("ProPromo Dark") {
    ProPromoView(onDismiss: {
        print("ProPromoView dismissed")
    })
    .preferredColorScheme(.dark)
}

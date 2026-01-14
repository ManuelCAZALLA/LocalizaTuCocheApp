import SwiftUI

/// Pantalla promocional de Pro que aparece antes de la pantalla principal
struct ProPromoView: View {
    @ObservedObject var subscriptionService = SubscriptionService.shared
    let onDismiss: () -> Void
    @State private var showProUpgrade = false
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("AppPrimary"),
                    Color("AppSecondary")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icono Pro
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                // Título
                VStack(spacing: 12) {
                    Text("upgrade_to_pro".localized)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    
                    Text("pro_promo_subtitle".localized)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Características destacadas - Las más atractivas
                VStack(spacing: 16) {
                    ProPromoFeatureRow(
                        icon: "xmark.circle.fill",
                        text: "no_ads".localized
                    )
                    ProPromoFeatureRow(
                        icon: "car.2.fill",
                        text: "multiple_vehicles".localized
                    )
                    ProPromoFeatureRow(
                        icon: "square.grid.2x2.fill",
                        text: "home_screen_widgets".localized
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Botón de acción
                Button(action: {
                    showProUpgrade = true
                }) {
                    HStack {
                        Text("discover_pro".localized)
                            .font(.headline)
                            .foregroundColor(Color("AppPrimary"))
                        
                        Image(systemName: "arrow.right")
                            .font(.headline)
                            .foregroundColor(Color("AppPrimary"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                
                // Barra de progreso (indicador de tiempo)
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(height: 4)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(2)
                    
                    Text("pro_promo_skip_hint".localized)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .fullScreenCover(isPresented: $showProUpgrade) {
            ProUpgradeView()
        }
        .onAppear {
            startTimer()
        }
    }
    
    private func startTimer() {
        // Animación de la barra de progreso
        withAnimation(.linear(duration: 5.0)) {
            progress = 1.0
        }
        
        // Después de 5 segundos, ocultar la promo y mostrar la app principal
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            onDismiss()
        }
    }
}

/// Fila de característica en la pantalla promocional
struct ProPromoFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

#Preview {
    ProPromoView(onDismiss: {})
}


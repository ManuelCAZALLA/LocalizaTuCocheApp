import SwiftUI
import RevenueCat

/// Vista para mostrar las ventajas de la versión Pro y permitir la compra
struct ProUpgradeView: View {
    @ObservedObject var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var availablePackages: [Package] = []
    @State private var isLoadingProducts = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Características Pro
                    featuresView
                    
                    // Productos disponibles
                    if !availablePackages.isEmpty {
                        productsView
                    } else if isLoadingProducts {
                        ProgressView()
                            .padding()
                    }
                    
                    // Botón de restaurar compras
                    restoreButton
                }
                .padding()
            }
            .navigationTitle("upgrade_to_pro".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("close".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProducts()
            }
            .alert("restore_purchases".localized, isPresented: $showRestoreAlert) {
                Button("ok".localized, role: .cancel) {}
            } message: {
                Text(restoreMessage)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("AppPrimary"), Color("AppSecondary")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Text("unlock_pro_features".localized)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("pro_description".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("pro_features".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Característica principal: Sin anuncios
            ProFeatureRow(
                icon: "xmark.circle.fill",
                title: "no_ads".localized,
                description: "no_ads_description".localized
            )
            
            // Múltiples vehículos - MUY valioso para familias
            ProFeatureRow(
                icon: "car.2.fill",
                title: "multiple_vehicles".localized,
                description: "multiple_vehicles_description".localized
            )
            
            // Widgets - Muy útil
            ProFeatureRow(
                icon: "square.grid.2x2.fill",
                title: "home_screen_widgets".localized,
                description: "home_screen_widgets_description".localized
            )
            
            // Compartir ubicación en tiempo real - Útil para que otros te encuentren
            ProFeatureRow(
                icon: "location.circle.fill",
                title: "share_live_location".localized,
                description: "share_live_location_description".localized
            )
            
            // Backup en iCloud - Importante para no perder datos
            ProFeatureRow(
                icon: "icloud.fill",
                title: "icloud_backup".localized,
                description: "icloud_backup_description".localized
            )
            
            // Historial ilimitado (en lugar de solo 10)
            ProFeatureRow(
                icon: "clock.arrow.circlepath",
                title: "unlimited_history".localized,
                description: "unlimited_history_description".localized
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var productsView: some View {
        VStack(spacing: 12) {
            ForEach(availablePackages, id: \.identifier) { package in
                ProductButton(
                    package: package,
                    isLoading: subscriptionService.isLoading
                ) {
                    purchasePackage(package)
                }
            }
        }
    }
    
    private var restoreButton: some View {
        Button(action: restorePurchases) {
            Text("restore_purchases".localized)
                .font(.body)
                .foregroundColor(Color("AppPrimary"))
        }
        .disabled(subscriptionService.isLoading)
    }
    
    private func loadProducts() {
        isLoadingProducts = true
        subscriptionService.getAvailablePackages { packages in
            DispatchQueue.main.async {
                self.availablePackages = packages
                self.isLoadingProducts = false
            }
        }
    }
    
    private func purchasePackage(_ package: Package) {
        subscriptionService.purchasePackage(package) { success, error in
            if success {
                dismiss()
            }
        }
    }
    
    private func restorePurchases() {
        subscriptionService.restorePurchases { success in
            restoreMessage = success ? "purchases_restored_success".localized : "purchases_restored_failed".localized
            showRestoreAlert = true
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
}

/// Fila de característica Pro
struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("AppPrimary"))
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

/// Botón de producto
struct ProductButton: View {
    let package: Package
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(package.storeProduct.localizedPriceString)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color("AppPrimary"), Color("AppSecondary")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

#Preview {
    ProUpgradeView()
}


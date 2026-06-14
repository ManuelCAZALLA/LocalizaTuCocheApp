import SwiftUI
import RevenueCat
import RevenueCatUI

struct MainTabView: View {
    @StateObject private var parkingViewModel = ParkingViewModel()
    @Binding var openParkingFromNotification: Bool
    @State private var selectedTab = 0
    @StateObject private var settingsViewModel = SettingsViewModel()

    @AppStorage("isPro") private var isPro = false
    @State private var lastNonHistoryTab = 0
    @State private var showHistoryGateSheet = false
    @State private var showPaywallSheet = false
    @State private var historyGateCompleted = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Inicio".localized, systemImage: "car.fill")
                }
                .tag(0)

            ParkingMeterView(
                parkingViewModel: parkingViewModel,
                openParkingFromNotification: $openParkingFromNotification
            )
            .tabItem {
                Label("Parquímetro".localized, systemImage: "timer")
            }
            .tag(1)

           RecentParkingsView()
                .tabItem {
                    Label("recent_parkings".localized, systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
            
            SettingView(viewModel: settingsViewModel)
                .tabItem {
                    Label("settings_tab_title".localized, systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { newValue in
            if newValue != 2 {
                lastNonHistoryTab = newValue
            }
            if newValue == 2, !isPro {
                historyGateCompleted = false
                showHistoryGateSheet = true
            }
        }
        .sheet(isPresented: $showHistoryGateSheet, onDismiss: {
            if !historyGateCompleted {
                selectedTab = lastNonHistoryTab
            }
            historyGateCompleted = false
        }) {
            ProOrAdGateSheet(
                title: "pro_gate_history_title".localized,
                message: "pro_gate_history_message".localized,
                gateCompleted: $historyGateCompleted,
                onUpgrade: { showPaywallSheet = true },
                onWatchAd: {
                    AdsService.shared.showInterstitial { }
                }
            )
        }
        .sheet(isPresented: $showPaywallSheet, onDismiss: {
            Task { await refreshProFromPurchases() }
        }) {
            PaywallView(displayCloseButton: true)
        }
        .onChange(of: openParkingFromNotification) { newValue in
            if newValue {
                selectedTab = 1
            }
        }
    }

    private func refreshProFromPurchases() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let hasPremium = Entitlement.isPremiumActive(in: info)
            await MainActor.run { isPro = hasPremium }
        } catch {
            await MainActor.run { isPro = false }
        }
    }
}

#Preview {
    MainTabView(openParkingFromNotification: .constant(false))
}

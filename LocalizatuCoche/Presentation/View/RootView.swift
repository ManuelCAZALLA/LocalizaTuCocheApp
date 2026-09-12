//
//  RootView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 30/6/25.
//

import SwiftUI
import GoogleMobileAds
import RevenueCat
import RevenueCatUI

struct RootView: View {
    @StateObject private var launchVM = LaunchViewModel()
    @EnvironmentObject var appState: AppState
    @AppStorage("isPro") private var isPro: Bool = false
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
    @AppStorage("lastLaunchPaywallTimestamp") private var lastLaunchPaywallTimestamp: Double = 0

    @State private var showLaunchPaywall = false
    @State private var didScheduleLaunchPaywall = false

    var body: some View {
        Group {
            if launchVM.isAuthorized {
                MainTabView(openParkingFromNotification: $appState.openParkingFromNotification)
            } else {
                LaunchView(viewModel: launchVM)
            }
        }
        .animation(.easeInOut, value: launchVM.isAuthorized)
        .preferredColorScheme(appColorScheme)
        .task {
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            await refreshProStatus()
            await MainActor.run {
                AdsService.shared.start()
            }
        }
        .onChange(of: launchVM.isAuthorized) { authorized in
            guard authorized else { return }
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            Task {
                await refreshProStatus()
                await MainActor.run {
                    presentLaunchPaywallIfNeeded()
                }
            }
        }
        .onChange(of: isPro) { isProNow in
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            if isProNow {
                showLaunchPaywall = false
            } else {
                AdsService.shared.start()
            }
        }
        .sheet(isPresented: $showLaunchPaywall, onDismiss: {
            Task { await refreshProStatus() }
        }) {
            PaywallView(displayCloseButton: true)
        }
    }

    private var appColorScheme: ColorScheme {
        guard isPro, isDarkModeEnabled else { return .light }
        return .dark
    }

    private func refreshProStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let hasPremium = Entitlement.isPremiumActive(in: info)
            await MainActor.run {
                isPro = hasPremium
                if !hasPremium {
                    isDarkModeEnabled = false
                }
            }
        } catch {
            await MainActor.run {
                isPro = false
                isDarkModeEnabled = false
            }
        }
    }

    /// Paywall al entrar: primera sesión y como mucho 1 vez cada N días. Nunca si ya es Pro.
    private func presentLaunchPaywallIfNeeded() {
        guard !isPro, !didScheduleLaunchPaywall else { return }
        guard shouldShowLaunchPaywallNow() else { return }

        didScheduleLaunchPaywall = true
        lastLaunchPaywallTimestamp = Date().timeIntervalSince1970

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard !isPro else { return }
            showLaunchPaywall = true
        }
    }

    private func shouldShowLaunchPaywallNow() -> Bool {
        guard lastLaunchPaywallTimestamp > 0 else { return true }
        let lastShown = Date(timeIntervalSince1970: lastLaunchPaywallTimestamp)
        let cooldown = TimeInterval(ProFeatureLimits.launchPaywallCooldownDays * 24 * 60 * 60)
        return Date().timeIntervalSince(lastShown) >= cooldown
    }
}


#Preview {
    RootView()
        .environmentObject(AppState())
}

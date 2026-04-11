//
//  RootView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 30/6/25.
//

import SwiftUI
import GoogleMobileAds
import RevenueCat

struct RootView: View {
    @StateObject private var launchVM = LaunchViewModel()
    @EnvironmentObject var appState: AppState
    @AppStorage("isPro") private var isPro: Bool = false
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled: Bool = false
    
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
            // Tras conocer el estado real de Pro (RevenueCat), cargar anuncios si el usuario es gratis.
            await MainActor.run {
                AdsService.shared.start()
            }
        }
        .onChange(of: isPro) { isProNow in
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
            if !isProNow {
                AdsService.shared.start()
            }
        }
    }

    private var appColorScheme: ColorScheme {
        guard isPro, isDarkModeEnabled else { return .light }
        return .dark
    }

    private func refreshProStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            let hasPremium = info.entitlements["Premium"]?.isActive == true
            await MainActor.run {
                isPro = hasPremium
                if !hasPremium {
                    isDarkModeEnabled = false
                }
            }
        } catch {
            // Si falla RevenueCat, mantenemos el estado persistido.
        }
    }
}


#Preview {
    RootView()
        .environmentObject(AppState())
}

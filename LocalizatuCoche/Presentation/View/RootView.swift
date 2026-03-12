//
//  RootView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 30/6/25.
//

import SwiftUI
import GoogleMobileAds

struct RootView: View {
    @StateObject private var launchVM = LaunchViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if launchVM.isAuthorized {
                MainTabView(openParkingFromNotification: $appState.openParkingFromNotification)
            } else {
                LaunchView(viewModel: launchVM)
            }
        }
        .animation(.easeInOut, value: launchVM.isAuthorized)
        .onAppear {
            // Inicializar Google Mobile Ads una vez al inicio
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                AdsService.shared.start()
            }
        }
    }
}


#Preview {
    RootView()
        .environmentObject(AppState())
}

//
//  RootView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 30/6/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var launchVM = LaunchViewModel()
    @EnvironmentObject var appState: AppState
    @AppStorage("isPro") private var isPro = false
    @AppStorage("hasSeenProPromoV1") private var hasSeenProPromo = false
    @State private var showProPromo = false
    
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
            if !isPro && !hasSeenProPromo {
                showProPromo = true
            }
        }
        .fullScreenCover(isPresented: $showProPromo) {
            ProPromoView {
                hasSeenProPromo = true
                showProPromo = false
            }
        }
    }
}


#Preview {
    RootView()
}

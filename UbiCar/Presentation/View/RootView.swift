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
    
    var body: some View {
        Group {
            if launchVM.isAuthorized {
                MainTabView(openParkingFromNotification: $appState.openParkingFromNotification)
            } else {
                LaunchView(viewModel: launchVM)
            }
        }
        .animation(.easeInOut, value: launchVM.isAuthorized)
    }
}


#Preview {
    RootView()
}

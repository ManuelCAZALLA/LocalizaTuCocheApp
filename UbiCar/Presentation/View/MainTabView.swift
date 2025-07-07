//
//  MainTabView.swift
//  UbiCar
//
//  Created by Manuel Cazalla Colmenero on 30/6/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var parkingViewModel = ParkingViewModel()
    @Binding var openParkingFromNotification: Bool
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Inicio", systemImage: "car.fill")
                }
                .tag(0)

            ParkingMeterView(parking: parkingViewModel.lastParking, openParkingFromNotification: $openParkingFromNotification)
                .tabItem {
                    Label("Parquímetro", systemImage: "timer")
                }
                .tag(1)

            SettingView()
                .tabItem {
                    Label("Opciones", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        
        .onChange(of: openParkingFromNotification) {
            if openParkingFromNotification {
                selectedTab = 1
            }
        }
    }
}

#Preview {
    MainTabView(openParkingFromNotification: .constant(false))
}

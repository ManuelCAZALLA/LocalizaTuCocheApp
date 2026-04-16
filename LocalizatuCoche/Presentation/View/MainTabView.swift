import SwiftUI

struct MainTabView: View {
    @StateObject private var parkingViewModel = ParkingViewModel()
    @Binding var openParkingFromNotification: Bool
    @State private var selectedTab = 0
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Inicio", systemImage: "car.fill")
                }
                .tag(0)

            ParkingMeterView(
                parkingViewModel: parkingViewModel,
                openParkingFromNotification: $openParkingFromNotification
            )
            .tabItem {
                Label("Parquímetro", systemImage: "timer")
            }
            .tag(1)

            SettingView(viewModel: settingsViewModel)
                .tabItem {
                    Label("settings_tab_title".localized, systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .onChange(of: openParkingFromNotification) { newValue in
            if newValue {
                selectedTab = 1
            }
        }
    }
}

#Preview {
    MainTabView(openParkingFromNotification: .constant(false))
}

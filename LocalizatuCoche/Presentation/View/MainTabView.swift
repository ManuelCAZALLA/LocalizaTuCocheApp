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
        // Mostrar anuncio cuando se cambia a la pestaña de "últimos aparcamientos"
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                AdsService.shared.showInterstitial {
                    // No hace falta hacer nada especial al cerrar el anuncio:
                    // la pestaña ya está seleccionada y la vista se muestra.
                }
            }
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

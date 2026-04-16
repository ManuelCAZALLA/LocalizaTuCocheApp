import SwiftUI
import CoreLocation

struct LaunchView: View {
    @ObservedObject var viewModel: LaunchViewModel
    @State private var showLocationDeniedAlert = false
    
    var body: some View {
        ZStack {
            // Fondo degradado profesional
            LinearGradient(gradient: Gradient(colors: [Color("AppPrimary"), Color("AppSecondary")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            Group {
                if viewModel.isAuthorized {
                    ContentView()
                } else {
                    VStack(spacing: 28) {
                        
                        Text("app_name".localized)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                            .padding(.top, 40)
                        
                        Text("find_car_easily".localized)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                        
                        Spacer(minLength: 0)
                        
                        Text("allow_location".localized)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            let manager = CLLocationManager()
                            let status = manager.authorizationStatus
                            if status == .denied || status == .restricted {
                                showLocationDeniedAlert = true
                            } else {
                                viewModel.requestAuthorization()
                            }
                        }) {
                            
                            Text("Permitir Ubicación")
                                .font(.title2.bold())
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.18))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(radius: 6)
                        }
                        
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                        .alert("location_permission_denied".localized, isPresented: $showLocationDeniedAlert) {
                            Button("open_settings".localized) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            Button("cancel".localized, role: .cancel) {}
                        } message: {
                            
                            Text("location_permission_message".localized)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .animation(.easeInOut, value: viewModel.isAuthorized)
        }
    }
}

#Preview {
    LaunchView(viewModel: LaunchViewModel())
}

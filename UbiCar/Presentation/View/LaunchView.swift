import SwiftUI

struct LaunchView: View {
    @ObservedObject var viewModel: LaunchViewModel
    
    var body: some View {
        ZStack {
            // Fondo degradado profesional
            LinearGradient(gradient: Gradient(colors: [Color.appPrimary, Color.secondary]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            Group {
                if viewModel.isAuthorized {
                    ContentView()
                } else {
                    VStack(spacing: 28) {
                        Text("UbicaTuCar")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                            .padding(.top, 40)
                        Text("Encuentra tu coche fácilmente")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                        Spacer(minLength: 0)
                        Text("Para empezar, necesitamos acceso a tu ubicación.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button(action: {
                            viewModel.requestAuthorization()
                        }) {
                            Text("Permitir ubicación")
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

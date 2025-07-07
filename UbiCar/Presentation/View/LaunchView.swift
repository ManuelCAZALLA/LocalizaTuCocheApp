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
                    VStack(spacing: 32) {
                        Image("UbiCar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .shadow(radius: 16)
                        Text("¡Bienvenido a UbiCar!")
                            .font(.largeTitle.bold())
                            .foregroundColor(.appPrimary)
                            .shadow(radius: 4)
                        Text("Te ayudamos a encontrar tu coche fácilmente. Para empezar, necesitamos acceso a tu ubicación.")
                            .font(.title3)
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
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(radius: 6)
                        }
                        .padding(.horizontal, 32)
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

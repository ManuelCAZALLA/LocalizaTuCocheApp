import SwiftUI

struct ParkingSavedSuccessOverlay: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isVisible = false
                    }
                }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isVisible ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .scaleEffect(isVisible ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isVisible)
                }
                
                VStack(spacing: 8) {
                    Text("¡Aparcamiento guardado!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Tu ubicación ha sido guardada correctamente")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeInOut.delay(0.3), value: isVisible)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        }
        .transition(.opacity)
    }
}

#Preview {
    ParkingSavedSuccessOverlay(isVisible: .constant(true))
}


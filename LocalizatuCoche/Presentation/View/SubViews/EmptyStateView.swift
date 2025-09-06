import SwiftUI

struct EmptyStateView: View {
    let isIPad: Bool
    
    var body: some View {
            
            VStack(spacing: isIPad ? 24 : 16) {
                // Icono adaptativo
                ZStack {
                    Circle()
                        .fill(Color("AppPrimary").opacity(0.1))
                        .frame(width: isIPad ? 120 : 80, height: isIPad ? 120 : 80)
                    
                    Image(systemName: "car.2.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isIPad ? 60 : 40, height: isIPad ? 60 : 40)
                        .foregroundColor(Color("AppPrimary"))
                        .opacity(0.7)
                }
                
                VStack(spacing: isIPad ? 12 : 8) {
                    Text("no_parking_today".localized)
                        .font(isIPad ? .system(size: 28, weight: .bold) : .title2)
                        .fontWeight(isIPad ? .bold : .semibold)
                        .foregroundColor(Color("AppPrimary"))
                        .multilineTextAlignment(.center)
                    
                    Text("no_parking_today_funny".localized)
                        .font(isIPad ? .system(size: 18, weight: .medium) : .body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Información adicional solo en iPad
                if isIPad {
                    HStack(spacing: 40) {
                        VStack(spacing: 8) {
                            Image(systemName: "location.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Ubicación automática")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            Image(systemName: "camera.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("Foto opcional")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            Image(systemName: "note.text.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Notas personalizadas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isIPad ? 50 : 40)
            .padding(.horizontal, isIPad ? 40 : 32)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 24 : 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(isIPad ? 0.08 : 0.05), radius: isIPad ? 16 : 12, x: 0, y: isIPad ? 8 : 6)
            )
            .padding(.horizontal)
    }
}

#Preview {
    EmptyStateView(isIPad: false)
}

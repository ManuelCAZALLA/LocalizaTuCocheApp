import SwiftUI

struct ActionButtonsRow: View {
    let hasPhoto: Bool
    let hasNote: Bool
    let onCameraTap: () -> Void
    let onNoteTap: () -> Void
    let isIPad: Bool
    
    var body: some View {
            
            HStack(spacing: isIPad ? 20 : 16) {
                // Botón de foto
                Button(action: onCameraTap) {
                    HStack(spacing: isIPad ? 12 : 8) {
                        Image(systemName: hasPhoto ? "camera.fill" : "camera")
                            .font(isIPad ? .title2 : .title3)
                        Text(hasPhoto ? "change_photo".localized : "add_photo".localized)
                            .font(isIPad ? .system(size: 16, weight: .semibold) : .body)
                            .fontWeight(isIPad ? .semibold : .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isIPad ? 18 : 14)
                    .background(
                        RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                            .fill(Color("AccentColor"))
                            .shadow(color: Color("AccentColor").opacity(0.3), radius: isIPad ? 6 : 4, x: 0, y: isIPad ? 3 : 2)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Botón de nota
                Button(action: onNoteTap) {
                    HStack(spacing: isIPad ? 12 : 8) {
                        Image(systemName: hasNote ? "pencil.circle.fill" : "pencil")
                            .font(isIPad ? .title2 : .title3)
                        Text(hasNote ? "edit_note".localized : "add_note".localized)
                            .font(isIPad ? .system(size: 16, weight: .semibold) : .body)
                            .fontWeight(isIPad ? .semibold : .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isIPad ? 18 : 14)
                    .background(
                        RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                            .fill(Color.orange)
                            .shadow(color: Color.orange.opacity(0.3), radius: isIPad ? 6 : 4, x: 0, y: isIPad ? 3 : 2)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
    }
}

#Preview {
    ActionButtonsRow(
        hasPhoto: false,
        hasNote: false,
        onCameraTap: {},
        onNoteTap: {},
        isIPad: false
    )
}

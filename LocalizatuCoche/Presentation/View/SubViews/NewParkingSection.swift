import SwiftUI

struct NewParkingSection: View {
    let parkingPhoto: UIImage?
    let onPhotoRemove: () -> Void
    let onCameraTap: () -> Void
    let onNoteTap: () -> Void
    let onSave: () -> Void
    let isSaveEnabled: Bool
    let isSaving: Bool
    let isIPad: Bool
    
    var body: some View {
            
            VStack(spacing: isIPad ? 24 : 20) {
                // Preview de foto si existe
                if let image = parkingPhoto {
                    PhotoPreviewView(image: image, onRemove: onPhotoRemove, isIPad: isIPad)
                }
                
                // Botones de acción mejorados
                ActionButtonsRow(
                    hasPhoto: parkingPhoto != nil,
                    hasNote: false,
                    onCameraTap: onCameraTap,
                    onNoteTap: onNoteTap,
                    isIPad: isIPad
                )
                
                // Botón principal de guardar usando ParkingButton
                ParkingButton(enabled: isSaveEnabled) {
                    onSave()
                }
                .scaleEffect(isIPad ? 1.1 : 1.0)
            }
            .padding(.horizontal, isIPad ? 24 : 16)
            .padding(.vertical, isIPad ? 20 : 16)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                    .fill(Color(.systemBackground).opacity(isIPad ? 0.6 : 1.0))
                    .shadow(color: Color.black.opacity(isIPad ? 0.05 : 0.0), radius: isIPad ? 10 : 0, x: 0, y: isIPad ? 5 : 0)
            )
            .padding(.horizontal)
    }
}

#Preview {
    NewParkingSection(
        parkingPhoto: nil,
        onPhotoRemove: {},
        onCameraTap: {},
        onNoteTap: {},
        onSave: {},
        isSaveEnabled: true,
        isSaving: false,
        isIPad: false
    )
}

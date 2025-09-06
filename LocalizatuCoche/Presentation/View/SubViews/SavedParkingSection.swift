import SwiftUI

struct SavedParkingSection: View {
    let parking: ParkingLocation
    let onDelete: () -> Void
    let onNavigate: () -> Void
    let onPhotoEdit: () -> Void
    let onNoteEdit: () -> Void
    @Binding var showMap: Bool
    let isIPad: Bool
    
    var body: some View {
            
            VStack(spacing: isIPad ? 20 : 16) {
                ParkingInfoCard(
                    parking: parking,
                    onDelete: onDelete,
                    onNavigate: onNavigate,
                    note: parking.note
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .scaleEffect(isIPad ? 1.02 : 1.0)
                
                // Botones de edición
                EditButtonsRow(
                    parking: parking,
                    onPhotoEdit: onPhotoEdit,
                    onNoteEdit: onNoteEdit,
                    isIPad: isIPad
                )
            }
            .padding(.horizontal, isIPad ? 24 : 16)
            .padding(.vertical, isIPad ? 20 : 16)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                    .fill(Color(.systemBackground).opacity(isIPad ? 0.6 : 1.0))
                    .shadow(color: Color.black.opacity(isIPad ? 0.05 : 0.0), radius: isIPad ? 10 : 0, x: 0, y: isIPad ? 5 : 0)
            )
            .padding(.horizontal)
            .fullScreenCover(isPresented: $showMap) {
                MapFullScreenView(parkingLocation: parking, onClose: { showMap = false })
            }
    }
}


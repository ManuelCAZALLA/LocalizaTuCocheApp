import SwiftUI

struct SavedParkingSectionView: View {
    let parking: ParkingLocation
    let note: String?
    let hasPhoto: Bool
    let onDelete: () -> Void
    let onEditPhoto: () -> Void
    let onEditNote: () -> Void
    @Binding var showMap: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ParkingInfoCard(
                parking: parking,
                onDelete: onDelete,
                onNavigate: { showMap = true },
                note: note
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
            
            HStack(spacing: 16) {
                Button(action: onEditPhoto) {
                    HStack(spacing: 8) {
                        Image(systemName: hasPhoto ? "camera.fill" : "camera")
                            .font(.body)
                        Text(hasPhoto ? "change_photo".localized : "add_photo".localized)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color("AccentColor").opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onEditNote) {
                    HStack(spacing: 8) {
                        Image(systemName: (note?.isEmpty ?? true) ? "pencil" : "pencil.circle.fill")
                            .font(.body)
                        Text((note?.isEmpty ?? true) ? "add_note".localized : "edit_note".localized)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .fullScreenCover(isPresented: $showMap) {
            MapFullScreenView(parkingLocation: parking, onClose: { showMap = false })
        }
    }
}

#Preview {
    SavedParkingSectionView(
        parking: ParkingLocation(
            latitude: 40.0,
            longitude: -3.0,
            date: Date(),
            placeName: "Gran Vía",
            note: "Frente al teatro"
        ),
        note: "Frente al teatro",
        hasPhoto: false,
        onDelete: {},
        onEditPhoto: {},
        onEditNote: {},
        showMap: .constant(false)
    )
}


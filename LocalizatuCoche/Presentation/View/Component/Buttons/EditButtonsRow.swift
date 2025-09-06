import SwiftUI

struct EditButtonsRow: View {
    let parking: ParkingLocation
    let onPhotoEdit: () -> Void
    let onNoteEdit: () -> Void
    let isIPad: Bool
    
    var body: some View {
            
            HStack(spacing: isIPad ? 20 : 16) {
                Button(action: onPhotoEdit) {
                    HStack(spacing: isIPad ? 12 : 8) {
                        Image(systemName: parking.photoData == nil ? "camera" : "camera.fill")
                            .font(isIPad ? .title3 : .body)
                        Text(parking.photoData == nil ? "add_photo".localized : "change_photo".localized)
                            .font(isIPad ? .system(size: 16, weight: .semibold) : .body)
                            .fontWeight(isIPad ? .semibold : .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isIPad ? 16 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                            .fill(Color("AccentColor"))
                            .shadow(color: Color("AccentColor").opacity(0.3), radius: isIPad ? 6 : 4, x: 0, y: isIPad ? 3 : 2)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onNoteEdit) {
                    HStack(spacing: isIPad ? 12 : 8) {
                        Image(systemName: (parking.note?.isEmpty ?? true) ? "pencil" : "pencil.circle.fill")
                            .font(isIPad ? .title3 : .body)
                        Text((parking.note?.isEmpty ?? true) ? "add_note".localized : "edit_note".localized)
                            .font(isIPad ? .system(size: 16, weight: .semibold) : .body)
                            .fontWeight(isIPad ? .semibold : .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isIPad ? 16 : 12)
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


import SwiftUI

struct NewParkingSectionView: View {
    let parkingPhoto: UIImage?
    let parkingNote: String
    let isSaving: Bool
    let isLocationAvailable: Bool
    let onTapPhoto: () -> Void
    let onTapNote: () -> Void
    let onSave: () -> Void
    let onRemovePhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = parkingPhoto {
                PhotoPreviewView(image: image, onRemove: onRemovePhoto)
            }
            
            HStack(spacing: 16) {
                Button(action: onTapPhoto) {
                    HStack(spacing: 8) {
                        Image(systemName: parkingPhoto == nil ? "camera" : "camera.fill")
                            .font(.title3)
                        Text(parkingPhoto == nil ? "add_photo".localized : "change_photo".localized)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("AccentColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color("AccentColor").opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .coachMarkTarget(id: "photoButton")
                
                Button(action: onTapNote) {
                    HStack(spacing: 8) {
                        Image(systemName: parkingNote.isEmpty ? "pencil" : "pencil.circle.fill")
                            .font(.title3)
                        Text(parkingNote.isEmpty ? "add_note".localized : "edit_note".localized)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .coachMarkTarget(id: "noteButton")
            }
            
            ParkingButton(enabled: isLocationAvailable && !isSaving) {
                onSave()
            }
            .coachMarkTarget(id: "saveButton")
        }
        .padding(.horizontal)
    }
}

private struct PhotoPreviewView: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("photo_preview".localized)
                    .font(.headline)
                    .foregroundColor(Color("AppPrimary"))
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    NewParkingSectionView(
        parkingPhoto: nil,
        parkingNote: "",
        isSaving: false,
        isLocationAvailable: true,
        onTapPhoto: {},
        onTapNote: {},
        onSave: {},
        onRemovePhoto: {}
    )
}


import SwiftUI

struct PhotoPreviewView: View {
    let image: UIImage
    let onRemove: () -> Void
    let isIPad: Bool
    
    var body: some View {
            
            VStack(alignment: .leading, spacing: isIPad ? 16 : 8) {
                HStack {
                    HStack(spacing: isIPad ? 8 : 4) {
                        Image(systemName: "photo.circle.fill")
                            .font(isIPad ? .title2 : .headline)
                            .foregroundColor(Color("AccentColor"))
                        Text("photo_preview".localized)
                            .font(isIPad ? .system(size: 20, weight: .semibold) : .headline)
                            .fontWeight(isIPad ? .semibold : .medium)
                            .foregroundColor(Color("AppPrimary"))
                    }
                    
                    Spacer()
                    
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(isIPad ? .title2 : .title3)
                            .scaleEffect(isIPad ? 1.1 : 1.0)
                    }
                }
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: isIPad ? 250 : 200)
                    .clipped()
                    .cornerRadius(isIPad ? 20 : 16)
                    .shadow(color: Color.black.opacity(isIPad ? 0.15 : 0.1), radius: isIPad ? 8 : 4, x: 0, y: isIPad ? 4 : 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                            .stroke(Color("AccentColor").opacity(isIPad ? 0.3 : 0.0), lineWidth: isIPad ? 2 : 0)
                    )
            }
            .padding(isIPad ? 20 : 16)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                    .fill(Color(.systemBackground).opacity(isIPad ? 0.8 : 1.0))
                    .shadow(color: Color.black.opacity(isIPad ? 0.08 : 0.05), radius: isIPad ? 12 : 4, x: 0, y: isIPad ? 6 : 2)
            )
    }
}

#Preview {
    PhotoPreviewView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onRemove: {},
        isIPad: false
    )
}

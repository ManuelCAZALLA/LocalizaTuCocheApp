import SwiftUI

struct HeaderView: View {
    let isIPad: Bool
    
    var body: some View {
        VStack(spacing: isIPad ? 16 : 12) {
            HStack(spacing: isIPad ? 16 : 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(Color("AccentColor"))
                    .font(isIPad ? .system(size: 32, weight: .medium) : .title2)
                    .scaleEffect(isIPad ? 1.2 : 1.0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("main_slogan".localized)
                        .font(isIPad ? .system(size: 28, weight: .semibold) : .title3)
                        .fontWeight(isIPad ? .semibold : .medium)
                        .foregroundColor(Color("AppPrimary"))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Línea decorativa solo en iPad
            if isIPad {
                Rectangle()
                    .fill(Color("AccentColor").opacity(0.3))
                    .frame(height: 2)
                    .frame(maxWidth: 200)
            }
        }
        .padding(.horizontal, isIPad ? 24 : 16)
        .padding(.vertical, isIPad ? 20 : 12)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .fill(Color(.systemBackground).opacity(isIPad ? 0.8 : 1.0))
                .shadow(color: Color.black.opacity(isIPad ? 0.05 : 0.0), radius: isIPad ? 10 : 0, x: 0, y: isIPad ? 5 : 0)
        )
        .padding(.horizontal)
    }
}

#Preview {
    HeaderView(isIPad: false)
}

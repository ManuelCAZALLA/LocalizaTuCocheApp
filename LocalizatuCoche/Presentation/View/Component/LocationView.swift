import SwiftUI
import CoreLocation

struct LocationView: View {
    let userLocation: CLLocationCoordinate2D?
    let placeName: String?
    let authorizationStatus: CLAuthorizationStatus
    let isIPad: Bool
    
    var body: some View {
        Group {
            if userLocation != nil {
                HStack(spacing: isIPad ? 20 : 12) {
                    ZStack {
                        Circle()
                            .fill(Color("AppSecondary").opacity(0.15))
                            .frame(width: isIPad ? 50 : 40, height: isIPad ? 50 : 40)
                        Image(systemName: "location.fill")
                            .foregroundColor(Color("AppSecondary"))
                            .font(isIPad ? .title2 : .title3)
                    }
                    
                    VStack(alignment: .leading, spacing: isIPad ? 6 : 2) {
                        Text("current_location".localized)
                            .font(isIPad ? .system(size: 14, weight: .medium) : .caption)
                            .foregroundColor(.secondary)
                            .textCase(isIPad ? .uppercase : .none)
                        
                        if let placeName = placeName {
                            Text(placeName)
                                .font(isIPad ? .system(size: 20, weight: .semibold) : .headline)
                                .foregroundColor(Color("AppPrimary"))
                                .lineLimit(isIPad ? 3 : 2)
                        } else {
                            HStack(spacing: isIPad ? 12 : 8) {
                                ProgressView()
                                    .scaleEffect(isIPad ? 1.0 : 0.8)
                                Text("getting_place_name".localized)
                                    .font(isIPad ? .system(size: 16, weight: .medium) : .subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Indicador de estado solo en iPad
                    if isIPad {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Activo")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(isIPad ? 24 : 16)
                .background(
                    RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(isIPad ? 0.08 : 0.05), radius: isIPad ? 12 : 8, x: 0, y: isIPad ? 6 : 4)
                )
                .padding(.horizontal)
            } else {
                LocationStatusView(status: authorizationStatus)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    LocationView(
        userLocation: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
        placeName: "Madrid, España",
        authorizationStatus: .authorizedWhenInUse,
        isIPad: false
    )
}

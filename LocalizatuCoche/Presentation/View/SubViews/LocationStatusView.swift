import SwiftUI
import CoreLocation

struct LocationStatusView: View {
    let status: CLAuthorizationStatus
    
    var body: some View {
        VStack(spacing: 6) {
            switch status {
            case .notDetermined:
                Label("waiting_location_permission".localized, systemImage: "location.slash")
                    .foregroundColor(.orange)
            case .restricted, .denied:
                Label("location_not_available".localized, systemImage: "location.xmark")
                    .foregroundColor(.red)
            case .authorizedAlways, .authorizedWhenInUse:
                ProgressView("getting_location".localized)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            default:
                Text("unknown_status".localized)
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
} 
import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @State private var cameraPosition: MapCameraPosition
    
    init(parkingLocation: ParkingLocation) {
        
        let coord = CLLocationCoordinate2D(latitude: parkingLocation.latitude, longitude: parkingLocation.longitude)
        _viewModel = StateObject(wrappedValue: MapViewModel(parkingLocation: coord))
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        ))
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            Map(position: $cameraPosition) {
                Annotation("Coche", coordinate: viewModel.parkingLocation) {
                    Image(systemName: "car.fill")
                        .font(.title)
                        .foregroundColor(.appPrimary)
                        .background(Circle().fill(Color.white).frame(width: 36, height: 36).shadow(radius: 4))
                }
                
                if let userCoord = viewModel.userLocation {
                    Annotation("Tú", coordinate: userCoord) {
                        VStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)
                            if let distance = viewModel.distanceToCar() {
                                Text("\(distance) m")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.white.opacity(0.85))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                // Dibuja la polilínea de la ruta si existe
                if let route = viewModel.route {
                    MapPolyline(route.polyline)
                        .stroke(Color.appPrimary, lineWidth: 7)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                viewModel.calculateRoute()
            }
           
        }
    }
}

struct MapFullScreenView: View {
    let parkingLocation: ParkingLocation
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            MapView(parkingLocation: parkingLocation)
                .edgesIgnoringSafeArea(.all)
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.appPrimary)
                        .padding(16)
                        .background(Color.white.opacity(0.85))
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }
                .padding(.top, 32)
                .padding(.trailing, 20)
            }
        }
    }
}

#Preview {
    let exampleParking = ParkingLocation(
        latitude: 40.4168,  // Madrid
        longitude: -3.7038,
        date: Date(),
        placeName: "Aparcado en la Gran Vía"
    )
    return MapView(parkingLocation: exampleParking)
}

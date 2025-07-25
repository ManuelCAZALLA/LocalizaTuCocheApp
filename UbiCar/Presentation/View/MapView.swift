import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @State private var cameraPosition: MapCameraPosition
    @State private var shouldAutoFit: Bool = true
    var onClose: (() -> Void)? = nil
    
    init(parkingLocation: ParkingLocation, onClose: (() -> Void)? = nil) {
        let coord = CLLocationCoordinate2D(latitude: parkingLocation.latitude, longitude: parkingLocation.longitude)
        _viewModel = StateObject(wrappedValue: MapViewModel(parkingLocation: coord))
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
        ))
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, interactionModes: .all) {
                Annotation("Coche", coordinate: viewModel.parkingLocation) {
                    Image(systemName: "car.fill")
                        .font(.title)
                        .foregroundColor(Color("AppPrimary"))
                        .background(Circle().fill(Color.white).frame(width: 36, height: 36).shadow(radius: 4))
                }
                if let userCoord = viewModel.userLocation {
                    Annotation("Tú", coordinate: userCoord) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .shadow(radius: 4)
                            
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(Color.blue)
                        }

                    }
                }
                if let polyline = viewModel.trimmedPolyline {
                    MapPolyline(polyline)
                        .stroke(Color("AppPrimary"), lineWidth: 7)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                shouldAutoFit = true
            }
            .gesture(DragGesture().onChanged { _ in
                shouldAutoFit = false
            })
            // Distancia/tiempo
            VStack() {
                HStack {
                    
                    if let distance = viewModel.distanceToCar(), let minutes = viewModel.expectedTravelTimeMinutes {
                        if distance >= 1000 {
                            Text(String(format: NSLocalizedString("distance_time_km", comment: ""), Double(distance)/1000.0, minutes))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(14)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                        } else {
                            Text(String(format: NSLocalizedString("distance_time", comment: ""), distance, minutes))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(14)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                        }
                    } else if let distance = viewModel.distanceToCar() {
                        if distance >= 1000 {
                            Text(String(format: NSLocalizedString("distance_km", comment: ""), Double(distance)/1000.0))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(14)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                        } else {
                            Text(String(format: NSLocalizedString("distance", comment: ""), distance))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(14)
                                .padding(.leading, 16)
                                .padding(.top, 16)
                        }
                    }
                    
                    Spacer()
                    
                    // Botón cerrar
                    if let onClose = onClose {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.85))
                                .padding(10)
                        }
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
        }
    }
}

struct MapFullScreenView: View {
    let parkingLocation: ParkingLocation
    let onClose: () -> Void
    
    var body: some View {
        MapView(parkingLocation: parkingLocation, onClose: onClose)
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

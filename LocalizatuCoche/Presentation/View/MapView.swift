import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    @State private var shouldAutoFit: Bool = true
    
    // Para iOS 16
    @State private var region: MKCoordinateRegion
    
    var onClose: (() -> Void)? = nil
    
    init(parkingLocation: ParkingLocation, onClose: (() -> Void)? = nil) {
        let coord = CLLocationCoordinate2D(latitude: parkingLocation.latitude, longitude: parkingLocation.longitude)
        _viewModel = StateObject(wrappedValue: MapViewModel(parkingLocation: coord))
        
        let initialRegion = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        _region = State(initialValue: initialRegion)
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if #available(iOS 17.0, *) {
                ios17MapView
            } else {
                ios16MapView
            }
            
            // Distancia/tiempo overlay (común para ambas versiones)
            distanceTimeOverlay
            
            // NUEVO: Overlay de indicaciones escritas
            instructionsOverlay
        }
    }
    
    // MARK: - iOS 17+ Map View
    @available(iOS 17.0, *)
    private var ios17MapView: some View {
        Map(position: .constant(.region(region)), interactionModes: .all) {
            Annotation("Coche".localized, coordinate: viewModel.parkingLocation) {
                carAnnotationView
            }
            if let userCoord = viewModel.userLocation {
                Annotation("Tú".localized, coordinate: userCoord) {
                    userAnnotationView
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
    }
    
    // MARK: - iOS 16 Map View
    @available(iOS 16.0, *)
    private var ios16MapView: some View {
        Map(coordinateRegion: $region, interactionModes: .all, annotationItems: annotationItems) { item in
            MapAnnotation(coordinate: item.coordinate) {
                if item.type == .car {
                    carAnnotationView
                } else {
                    userAnnotationView
                }
            }
        }
        .overlay(
            // Para iOS 16, dibujamos la polyline como overlay si es necesario
            polylineOverlay
        )
        .ignoresSafeArea()
        .onAppear {
            shouldAutoFit = true
            updateRegionForAnnotations()
        }
        .gesture(DragGesture().onChanged { _ in
            shouldAutoFit = false
        })
    }
    
    // MARK: - Annotation Views
    private var carAnnotationView: some View {
        Image(systemName: "car.fill")
            .font(.title)
            .foregroundColor(Color("AppPrimary"))
            .background(
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 4)
            )
    }
    
    private var userAnnotationView: some View {
        Image(systemName: "person.fill")
            .font(.title)
            .foregroundColor(.accentColor)
            .background(
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                    .shadow(radius: 4)
            )
    }
    
    // MARK: - Distance/Time Overlay
    private var distanceTimeOverlay: some View {
        VStack {
            HStack {
                if let distance = viewModel.distanceToCar(), let minutes = viewModel.expectedTravelTimeMinutes {
                    distanceTimeText(distance: distance, minutes: minutes)
                } else if let distance = viewModel.distanceToCar() {
                    distanceOnlyText(distance: distance)
                }
                
                Spacer()
                
                // Botón cerrar
                if let onClose = onClose {
                    closeButton(action: onClose)
                }
            }
            Spacer()
        }
    }
    
    // MARK: - NUEVO: Instructions Overlay
    private var instructionsOverlay: some View {
        VStack {
            Spacer()
            
            if viewModel.currentStepInstruction != nil || viewModel.nextStepInstruction != nil {
                VStack(spacing: 8) {
                    // Instrucción actual
                    if let currentInstruction = viewModel.currentStepInstruction {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            
                            Text(currentInstruction)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                    
                    // Próxima instrucción
                    if let nextInstruction = viewModel.nextStepInstruction {
                        Divider()
                        
                        HStack {
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            
                            Text("Siguiente: ".localized + nextInstruction)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func distanceTimeText(distance: Int, minutes: Int) -> some View {
        Group {
            if distance >= 1000 {
                Text(String(format: NSLocalizedString("distance_time_km", comment: ""), Double(distance)/1000.0, minutes))
            } else {
                Text(String(format: NSLocalizedString("distance_time", comment: ""), distance, minutes))
            }
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(14)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
    
    private func distanceOnlyText(distance: Int) -> some View {
        Group {
            if distance >= 1000 {
                Text(String(format: NSLocalizedString("distance_km", comment: ""), Double(distance)/1000.0))
            } else {
                Text(String(format: NSLocalizedString("distance", comment: ""), distance))
            }
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(14)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
    
    private func closeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
    
    // MARK: - iOS 16 Support
    private var annotationItems: [MapAnnotationItem] {
        var items: [MapAnnotationItem] = [
            MapAnnotationItem(coordinate: viewModel.parkingLocation, type: .car)
        ]
        
        if let userCoord = viewModel.userLocation {
            items.append(MapAnnotationItem(coordinate: userCoord, type: .user))
        }
        
        return items
    }
    
    private var polylineOverlay: some View {
        // Para iOS 16, podrías implementar un overlay personalizado para la polyline
        // o usar una librería externa. Por simplicidad, lo dejamos vacío aquí.
        EmptyView()
    }
    
    private func updateRegionForAnnotations() {
        guard shouldAutoFit else { return }
        
        var coordinates = [viewModel.parkingLocation]
        if let userLocation = viewModel.userLocation {
            coordinates.append(userLocation)
        }
        
        if coordinates.count > 1 {
            let region = calculateRegion(for: coordinates)
            withAnimation(.easeInOut(duration: 1.0)) {
                self.region = region
            }
        }
    }
    
    private func calculateRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        
        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.005) * 1.3,
            longitudeDelta: max(maxLon - minLon, 0.005) * 1.3
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Supporting Types
struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    
    enum AnnotationType {
        case car, user
    }
}

struct MapFullScreenView: View {
    let parkingLocation: ParkingLocation
    let onClose: () -> Void
    
    var body: some View {
        MapView(parkingLocation: parkingLocation, onClose: onClose)
    }
}

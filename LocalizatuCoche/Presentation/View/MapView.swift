import SwiftUI
import MapKit
import UIKit

struct MapView: View {
    @StateObject private var viewModel: MapViewModel
    
    // Cámara aplicada por código (auto-fit / centrar / seguir).
    @State private var region: MKCoordinateRegion
    // Se incrementa cada vez que el código aplica una cámara programática.
    @State private var programmaticToken: Int = 0
    @State private var shouldAutoFit: Bool = true
    @State private var isFollowingUser: Bool = false
    @State private var useHybridMap: Bool = false
    
    // Coach marks
    @AppStorage("hasShownMapOnboardingV1") private var hasShownMapOnboarding = false
    @State private var mapCoachTargets: [String: Anchor<CGRect>] = [:]
    @State private var mapCoachSteps: [CoachMark] = []
    @State private var mapCoachIndex: Int = 0
    @State private var showMapCoach: Bool = false
    
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
            mapKitMapView
            
            topBar
            bottomOverlay
            
            if showMapCoach, mapCoachIndex < mapCoachSteps.count {
                CoachMarksOverlay(
                    step: mapCoachSteps[mapCoachIndex],
                    targets: mapCoachTargets,
                    onNext: advanceMapCoach,
                    onSkip: finishMapCoach
                )
            }
        }
        .overlayPreferenceValue(CoachMarkTargetsKey.self) { value in
            GeometryReader { _ in
                Color.clear
                    .onAppear { mapCoachTargets = value }
                    .onChange(of: value) { newVal in
                        mapCoachTargets = newVal
                        if !showMapCoach, let first = mapCoachSteps.first, newVal[first.id] != nil {
                            withAnimation(.easeInOut(duration: 0.25)) { showMapCoach = true }
                        }
                    }
            }
        }
        .onAppear {
            shouldAutoFit = true
            prepareMapCoachIfNeeded()
            if viewModel.userLocation != nil {
                fitAnnotations()
            }
        }
        .onChange(of: viewModel.userLocation) { newLocation in
            if isFollowingUser, let location = newLocation {
                applyProgrammaticRegion(regionCenteredOn(location, spanDelta: 0.003))
            } else if shouldAutoFit {
                fitAnnotations()
            }
        }
        .onReceive(viewModel.$trimmedPolyline) { polyline in
            guard polyline != nil else { return }
            if shouldAutoFit {
                fitAnnotations()
            }
        }
    }
    
    // MARK: - Cámara / Región
    
    private func fitAnnotations() {
        var coordinates = [viewModel.parkingLocation]
        if let userLocation = viewModel.userLocation {
            coordinates.append(userLocation)
        }
        applyProgrammaticRegion(fittedRegion(for: coordinates))
    }
    
    private func focusOnCar() {
        isFollowingUser = false
        shouldAutoFit = false
        applyProgrammaticRegion(regionCenteredOn(viewModel.parkingLocation, spanDelta: 0.002))
    }
    
    private func toggleFollow() {
        if isFollowingUser {
            isFollowingUser = false
            shouldAutoFit = false
        } else {
            isFollowingUser = true
            shouldAutoFit = false
            if let userLocation = viewModel.userLocation {
                applyProgrammaticRegion(regionCenteredOn(userLocation, spanDelta: 0.003))
            }
        }
    }
    
    private func applyProgrammaticRegion(_ newRegion: MKCoordinateRegion) {
        region = newRegion
        programmaticToken += 1
    }
    
    private func regionCenteredOn(_ coordinate: CLLocationCoordinate2D, spanDelta: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
        )
    }
    
    private func fittedRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coordinates.first else {
            return regionCenteredOn(viewModel.parkingLocation, spanDelta: 0.005)
        }
        
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for coordinate in coordinates.dropFirst() {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let rawLatSpan = max(maxLat - minLat, 0.004)
        let rawLonSpan = max(maxLon - minLon, 0.004)
        let span = MKCoordinateSpan(latitudeDelta: rawLatSpan * 1.4, longitudeDelta: rawLonSpan * 1.4)
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Barra superior / Acciones
    
    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                distanceTimeView
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
                googleMapsButton
                
                if let onClose = onClose {
                    closeButton(action: onClose)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            HStack {
                Spacer()
                mapActionButtons
                    .padding(.trailing, 16)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
    }
    
    private var mapActionButtons: some View {
        VStack(spacing: 10) {
            followButton
            focusCarButton
            mapTypeButton
        }
    }
    
    private var followButton: some View {
        actionButton(icon: isFollowingUser ? "location.fill" : "location",
                     isActive: isFollowingUser,
                     accessibilityLabel: isFollowingUser ? "follow_off".localized : "follow_on".localized) {
            toggleFollow()
        }
    }
    
    private var focusCarButton: some View {
        actionButton(icon: "car.fill",
                     isActive: false,
                     accessibilityLabel: "focus_car".localized) {
            focusOnCar()
        }
    }
    
    private var mapTypeButton: some View {
        actionButton(icon: useHybridMap ? "map.fill" : "square.2.layers.3d.fill",
                     isActive: false,
                     accessibilityLabel: useHybridMap ? "map_standard".localized : "map_hybrid".localized) {
            withAnimation(.easeInOut(duration: 0.3)) { useHybridMap.toggle() }
        }
    }
    
    private func actionButton(icon: String, isActive: Bool, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isActive ? .white : Color.primary)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isActive ? Color("AppPrimary") : Color(.systemBackground).opacity(0.9))
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Distancia / Tiempo
    
    private var distanceTimeView: some View {
        Group {
            if let distance = viewModel.distanceToCar(), let minutes = viewModel.expectedTravelTimeMinutes {
                distanceTimeText(distance: distance, minutes: minutes)
            } else if let distance = viewModel.distanceToCar() {
                distanceOnlyText(distance: distance)
            } else {
                // Placeholder para mantener el espacio cuando no hay datos
                Text("loading".localized)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground).opacity(0.8))
                    .clipShape(Capsule())
                    .hidden()
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
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
    
    private func distanceOnlyText(distance: Int) -> some View {
        Group {
            if distance >= 1000 {
                Text(String(format: NSLocalizedString("distance_km", comment: ""), Double(distance)/1000.0))
            } else {
                Text(String(format: NSLocalizedString("distance", comment: ""), distance))
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Mapa

    private var mapKitMapView: some View {
        CarParkingMapView(
            carCoordinate: viewModel.parkingLocation,
            userCoordinate: viewModel.userLocation,
            polyline: viewModel.trimmedPolyline,
            programmaticRegion: region,
            programmaticToken: programmaticToken,
            mapType: useHybridMap ? .hybrid : .standard,
            onUserPan: {
                shouldAutoFit = false
                isFollowingUser = false
            }
        )
        .ignoresSafeArea()
        .onAppear {
            shouldAutoFit = true
        }
    }
    
    // MARK: - Annotation Views
    
    private var carAnnotationView: some View {
        Image(systemName: "car.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Color("AppPrimary"))
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 4)
            )
    }
    
    private var userAnnotationView: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.accentColor)
            .frame(width: 32, height: 32)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 4)
            )
    }
    
    // MARK: - Brújula y Overlay Inferior
    
    private var bottomOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 10) {
                compassArrow
                
                if viewModel.currentStepInstruction != nil || viewModel.nextStepInstruction != nil {
                    instructionsCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    private var compassArrow: some View {
        Group {
            if let bearing = viewModel.bearingToCar, let heading = viewModel.deviceHeading {
                let relative = Self.normalizedDegrees(bearing - heading)
                
                HStack(spacing: 10) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("AppPrimary"))
                        .rotationEffect(.degrees(relative))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("towards_your_car".localized)
                            .font(.caption.weight(.semibold))
                        Text("\(Int(relative.rounded()))°")
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.2), value: viewModel.deviceHeading)
            }
        }
    }
    
    private var instructionsCard: some View {
        VStack(spacing: 8) {
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
    }
    
    // MARK: - Botón Google Maps
    
    private var googleMapsButton: some View {
        Button(action: openInGoogleMaps) {
            Image(systemName: "map.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
        }
        .background(Color("AppPrimary"))
        .clipShape(Circle())
        .buttonStyle(.plain)
        .coachMarkTarget(id: "googleMapsButton")
    }
    
    private func closeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
        }
        .background(Color.black.opacity(0.4))
        .clipShape(Circle())
        .buttonStyle(.plain)
    }
    
    private func openInGoogleMaps() {
        let latitude = viewModel.parkingLocation.latitude
        let longitude = viewModel.parkingLocation.longitude
        
        let googleMapsURL = "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=walking"
        let googleMapsWebURL = "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)&travelmode=walking"
        
        if let url = URL(string: googleMapsURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let webURL = URL(string: googleMapsWebURL) {
            UIApplication.shared.open(webURL)
        }
    }
    
    private static func normalizedDegrees(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360)
        if result > 180 { result -= 360 }
        if result < -180 { result += 360 }
        return result
    }
}

// MARK: - Coach marks (Map)
extension MapView {
    private func prepareMapCoachIfNeeded() {
        guard !hasShownMapOnboarding else { return }
        mapCoachSteps = [
            CoachMark(id: "googleMapsButton", textKey: "coach_google_maps"),
        ]
        mapCoachIndex = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showMapCoach = true
            }
        }
    }
    private func advanceMapCoach() {
        let next = mapCoachIndex + 1
        if next < mapCoachSteps.count {
            withAnimation(.easeInOut(duration: 0.25)) { mapCoachIndex = next }
        } else {
            finishMapCoach()
        }
    }
    private func finishMapCoach() {
        withAnimation(.easeInOut(duration: 0.25)) { showMapCoach = false }
        hasShownMapOnboarding = true
    }
}

struct MapFullScreenView: View {
    let parkingLocation: ParkingLocation
    let onClose: () -> Void
    
    var body: some View {
        MapView(parkingLocation: parkingLocation, onClose: onClose)
    }
}

// MARK: - MKMapView representable (añade ruta, anotaciones y cámara)
struct CarParkingMapView: UIViewRepresentable {
    let carCoordinate: CLLocationCoordinate2D
    let userCoordinate: CLLocationCoordinate2D?
    let polyline: MKPolyline?
    let programmaticRegion: MKCoordinateRegion
    let programmaticToken: Int
    let mapType: MKMapType
    let onUserPan: () -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsBuildings = true
        mapView.mapType = mapType
        mapView.setRegion(programmaticRegion, animated: false)
        
        context.coordinator.lastAppliedToken = programmaticToken
        context.coordinator.lastAppliedRegion = programmaticRegion
        updateAnnotationsAndOverlay(on: mapView, coordinator: context.coordinator)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        
        if context.coordinator.lastAppliedToken != programmaticToken {
            context.coordinator.lastAppliedToken = programmaticToken
            context.coordinator.lastAppliedRegion = programmaticRegion
            mapView.setRegion(programmaticRegion, animated: true)
        }
        
        if context.coordinator.needsContentUpdate(
            car: carCoordinate,
            user: userCoordinate,
            polyline: polyline
        ) {
            updateAnnotationsAndOverlay(on: mapView, coordinator: context.coordinator)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onUserPan: onUserPan)
    }
    
    private func updateAnnotationsAndOverlay(on mapView: MKMapView, coordinator: Coordinator) {
        mapView.removeOverlays(mapView.overlays)
        if let polyline = polyline {
            let casing = MKPolyline(points: polyline.points(), count: polyline.pointCount)
            coordinator.casingPolyline = casing
            mapView.addOverlay(casing)
            mapView.addOverlay(polyline)
        } else {
            coordinator.casingPolyline = nil
        }
        
        mapView.removeAnnotations(mapView.annotations)
        
        let car = MKPointAnnotation()
        car.coordinate = carCoordinate
        car.title = "Coche"
        mapView.addAnnotation(car)
        
        if let userCoordinate = userCoordinate {
            let user = MKPointAnnotation()
            user.coordinate = userCoordinate
            user.title = "Tú"
            mapView.addAnnotation(user)
        }
        
        coordinator.appliedCar = carCoordinate
        coordinator.appliedUser = userCoordinate
        coordinator.appliedPolyline = polyline
    }
    
    final class Coordinator: NSObject, MKMapViewDelegate {
        var lastAppliedToken: Int = -1
        var lastAppliedRegion: MKCoordinateRegion?
        var appliedCar: CLLocationCoordinate2D?
        var appliedUser: CLLocationCoordinate2D?
        var appliedPolyline: MKPolyline?
        weak var casingPolyline: MKPolyline?
        private let onUserPan: () -> Void
        
        init(onUserPan: @escaping () -> Void) {
            self.onUserPan = onUserPan
        }
        
        func needsContentUpdate(car: CLLocationCoordinate2D, user: CLLocationCoordinate2D?, polyline: MKPolyline?) -> Bool {
            if appliedCar != car { return true }
            if appliedUser != user { return true }
            if appliedPolyline !== polyline { return true }
            return false
        }
        
        // MARK: MKMapViewDelegate
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard let last = lastAppliedRegion else { return }
            
            let current = mapView.region
            let moved = CLLocation(latitude: current.center.latitude, longitude: current.center.longitude)
                .distance(from: CLLocation(latitude: last.center.latitude, longitude: last.center.longitude))
            let zoomed = abs(current.span.latitudeDelta - last.span.latitudeDelta) > 0.001
                || abs(current.span.longitudeDelta - last.span.longitudeDelta) > 0.001
            
            if moved > 30 || zoomed {
                onUserPan()
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let point = annotation as? MKPointAnnotation else { return nil }
            
            let isCar = point.title == "Coche"
            let identifier = isCar ? "carAnnotation" : "userAnnotation"
            
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.image = isCar ? Self.carImage : Self.userImage
            view.centerOffset = .zero
            return view
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                let isCasing = polyline === casingPolyline
                renderer.strokeColor = isCasing ? UIColor.white.withAlphaComponent(0.85) : (UIColor(named: "AppPrimary") ?? .systemBlue)
                renderer.lineWidth = isCasing ? 13 : 7
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        private static let carImage: UIImage = {
            circleIcon(systemName: "car.fill", tint: UIColor.ltcAppPrimary)
        }()
        
        private static let userImage: UIImage = {
            circleIcon(systemName: "person.fill", tint: .systemGreen)
        }()
        
        private static func circleIcon(systemName: String, tint: UIColor) -> UIImage {
            let size: CGFloat = 36
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            return renderer.image { context in
                UIColor.white.setFill()
                UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: size - 2, height: size - 2)).fill()
                
                let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
                if let symbol = UIImage(systemName: systemName, withConfiguration: configuration) {
                    tint.setFill()
                    let symbolRect = CGRect(
                        x: (size - symbol.size.width) / 2,
                        y: (size - symbol.size.height) / 2,
                        width: symbol.size.width,
                        height: symbol.size.height
                    )
                    symbol.draw(in: symbolRect)
                }
            }
        }
    }
}

private extension UIColor {
    static var ltcAppPrimary: UIColor {
        UIColor(named: "AppPrimary") ?? .systemBlue
    }
}
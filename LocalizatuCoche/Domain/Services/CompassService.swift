import Foundation
import CoreLocation
import Combine

final class CompassService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: CLHeading?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var magneticHeading: Double = 0
    @Published var trueHeading: Double = 0
    @Published var headingAccuracy: Double = 0
    @Published var isCalibrationRequired = false

    private let locationManager = CLLocationManager()
    private var headingBuffer: [Double] = [] // Para suavizar lecturas del compass
    private let maxBufferSize = 5
    
    // Estados para navegación
    @Published var bearingToTarget: Double?
    @Published var targetCoordinate: CLLocationCoordinate2D?
    @Published var isNavigatingWithCompass = false

    override init() {
        super.init()
        configureLocationManager()
    }
    
    deinit {
        stopUpdatingHeading()
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 2 // Actualizar si cambia más de 2 grados (reducido para más precisión)
        
        // Configurar orientación del dispositivo
        locationManager.headingOrientation = .portrait
        
        startLocationServices()
    }
    
    private func startLocationServices() {
        // Solicitar permisos si es necesario
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Verificar disponibilidad del magnetómetro
        guard CLLocationManager.headingAvailable() else {
            print("❌ Magnetómetro no disponible en este dispositivo")
            return
        }
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        print("🧭 Servicios de compass iniciados")
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        
        // Limpiar estados
        headingBuffer.removeAll()
        bearingToTarget = nil
        targetCoordinate = nil
        isNavigatingWithCompass = false
        
        print("🧭 Servicios de compass detenidos")
    }
    
    // MARK: - Navigation Methods
    
    /// Iniciar navegación con compass hacia un destino específico
    func startCompassNavigation(to target: CLLocationCoordinate2D) {
        targetCoordinate = target
        isNavigatingWithCompass = true
        updateBearingToTarget()
        
        print("🧭 Navegación con compass iniciada hacia: \(target)")
    }
    
    /// Detener navegación con compass
    func stopCompassNavigation() {
        targetCoordinate = nil
        bearingToTarget = nil
        isNavigatingWithCompass = false
        
        print("🧭 Navegación con compass detenida")
    }
    
    private func updateBearingToTarget() {
        guard let userLocation = userLocation,
              let target = targetCoordinate else {
            bearingToTarget = nil
            return
        }
        
        let bearing = calculateBearing(from: userLocation, to: target)
        
        DispatchQueue.main.async {
            self.bearingToTarget = bearing
        }
    }
    
    private func calculateBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Filtrar lecturas con baja precisión
        guard newHeading.headingAccuracy >= 0 else {
            // Heading accuracy negativo indica datos inválidos
            DispatchQueue.main.async {
                self.isCalibrationRequired = true
            }
            return
        }
        
        // Suavizar las lecturas del compass
        let smoothedHeading = smoothHeading(newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading)
        
        DispatchQueue.main.async {
            self.heading = newHeading
            self.magneticHeading = newHeading.magneticHeading
            self.trueHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : smoothedHeading
            self.headingAccuracy = newHeading.headingAccuracy
            self.isCalibrationRequired = newHeading.headingAccuracy < 0 || newHeading.headingAccuracy > 15
            
            // Actualizar bearing al objetivo si estamos navegando
            if self.isNavigatingWithCompass {
                self.updateBearingToTarget()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else { return }
        
        // Filtrar ubicaciones con baja precisión
        guard lastLocation.horizontalAccuracy <= 50 else { return }
        
        DispatchQueue.main.async {
            self.userLocation = lastLocation.coordinate
            
            // Actualizar bearing si estamos navegando
            if self.isNavigatingWithCompass {
                self.updateBearingToTarget()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Error de compass/ubicación: \(error.localizedDescription)")
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Mostrar calibración automáticamente si la precisión es baja
        return headingAccuracy < 0 || headingAccuracy > 20
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationServices()
        case .denied, .restricted:
            print("❌ Permisos de ubicación denegados para compass")
            stopUpdatingHeading()
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func smoothHeading(_ newHeading: Double) -> Double {
        headingBuffer.append(newHeading)
        
        // Mantener buffer limitado
        if headingBuffer.count > maxBufferSize {
            headingBuffer.removeFirst()
        }
        
        // Si solo tenemos una lectura, devolverla
        if headingBuffer.count == 1 {
            return newHeading
        }
        
        // Calcular promedio circular para ángulos
        var sinSum: Double = 0
        var cosSum: Double = 0
        
        for heading in headingBuffer {
            let radians = heading * .pi / 180
            sinSum += sin(radians)
            cosSum += cos(radians)
        }
        
        let avgRadians = atan2(sinSum / Double(headingBuffer.count), cosSum / Double(headingBuffer.count))
        let avgDegrees = avgRadians * 180 / .pi
        
        return avgDegrees < 0 ? avgDegrees + 360 : avgDegrees
    }
    
    /// Obtener la dirección cardinal actual como texto
    var currentDirection: String {
        let directions = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
        let index = Int((trueHeading + 22.5) / 45) % 8
        return directions[index]
    }
    
    /// Calcular la diferencia angular entre el heading actual y el bearing al objetivo
    var angleToTarget: Double? {
        guard let bearing = bearingToTarget else { return nil }
        
        let difference = bearing - trueHeading
        
        // Normalizar la diferencia a rango [-180, 180]
        if difference > 180 {
            return difference - 360
        } else if difference < -180 {
            return difference + 360
        } else {
            return difference
        }
    }
    
    /// Obtener texto de dirección hacia el objetivo
    var directionToTarget: String? {
        guard let angle = angleToTarget else { return nil }
        
        if abs(angle) < 15 {
            return "Directo"
        } else if angle > 0 {
            return "Gira a la derecha"
        } else {
            return "Gira a la izquierda"
        }
    }
    
    /// Verificar si el compass tiene buena precisión
    var hasGoodAccuracy: Bool {
        headingAccuracy >= 0 && headingAccuracy <= 10
    }
    
    /// Obtener distancia al objetivo (si tenemos ubicación actual y objetivo)
    var distanceToTarget: CLLocationDistance? {
        guard let userLocation = userLocation,
              let target = targetCoordinate else { return nil }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetCLLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
        
        return userCLLocation.distance(from: targetCLLocation)
    }
    
    /// Forzar calibración del compass
    func requestCalibration() {
        locationManager.dismissHeadingCalibrationDisplay()
        
        // Reiniciar servicios de heading para forzar recalibración
        locationManager.stopUpdatingHeading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.locationManager.startUpdatingHeading()
        }
    }
}

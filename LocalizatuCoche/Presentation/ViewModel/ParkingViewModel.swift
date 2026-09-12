import Foundation
import CoreLocation
import Combine
import AVFoundation

final class ParkingViewModel: NSObject, ObservableObject {
    @Published var lastParking: ParkingLocation?
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var placeName: String?
    
    private let parkingKey = "lastParkingLocation"
    private let locationManager = CLLocationManager()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastGeocodeDate: Date? = nil
    
    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
        loadParkingLocation()
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func saveParkingLocation(note: String? = nil, photoData: Data? = nil) {
        guard let coordinate = userLocation else { return }
        let parking = ParkingLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            date: Date(),
            placeName: placeName,
            note: note,
            photoData: photoData
        )
        ParkingStorage.shared.save(parking)
        lastParking = parking
    }
    
    func loadParkingLocation() {
        lastParking = ParkingStorage.shared.load()
    }
    
    func clearParkingLocation() {
        ParkingStorage.shared.clear()
        lastParking = nil
    }
    
    // MARK: - Nueva función para actualizar el nombre del lugar
    func updatePlaceName() {
        let now = Date()
        if let last = lastGeocodeDate, now.timeIntervalSince(last) < 10 {
            return
        }
        lastGeocodeDate = now
        guard let location = userLocation else { return }
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        CLGeocoder().reverseGeocodeLocation(loc) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                let name = placemark.name ?? placemark.locality ?? placemark.country
                DispatchQueue.main.async {
                    self?.placeName = name
                }
            } else {
                DispatchQueue.main.async {
                    self?.placeName = nil
                }
            }
        }
    }

    func updateParkingNote(note: String) {
        guard var parking = lastParking else { return }
        parking = ParkingLocation(
            latitude: parking.latitude,
            longitude: parking.longitude,
            date: parking.date,
            placeName: parking.placeName,
            note: note,
            id: parking.id
        )
        ParkingStorage.shared.save(parking)
        lastParking = parking
    }

    func updateParkingPhoto(photoData: Data?) {
        guard var parking = lastParking else { return }
        parking = ParkingLocation(
            latitude: parking.latitude,
            longitude: parking.longitude,
            date: parking.date,
            placeName: parking.placeName,
            note: parking.note,
            photoData: photoData,
            id: parking.id
        )
        ParkingStorage.shared.save(parking)
        lastParking = parking
    }
}

extension ParkingViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        userLocation = newLocation.coordinate
        updatePlaceName()  // Llamamos aquí para mantener placeName actualizado
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        userLocation = nil
        placeName = nil
    }
}

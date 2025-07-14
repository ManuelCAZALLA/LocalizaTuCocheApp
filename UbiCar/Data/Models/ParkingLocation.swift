import Foundation
import CoreLocation

struct ParkingLocation: Codable, Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let date: Date
    let placeName: String?
    let note: String?
    var photoData: Data? // Nueva propiedad para la foto

    init(latitude: Double, longitude: Double, date: Date, placeName: String?, note: String? = nil, photoData: Data? = nil, id: UUID = UUID()) {
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.placeName = placeName
        self.note = note
        self.photoData = photoData
        self.id = id
    }
} 
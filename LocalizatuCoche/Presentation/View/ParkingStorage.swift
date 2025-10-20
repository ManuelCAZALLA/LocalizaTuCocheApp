import Foundation
import CoreLocation

final class ParkingStorage {
    static let shared = ParkingStorage()
    private let key = "saved_parking_location"

    func save(_ parking: ParkingLocation) {
        do {
            let data = try JSONEncoder().encode(parking)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("❌ Error guardando parking: \(error)")
        }
    }

    func load() -> ParkingLocation? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(ParkingLocation.self, from: data)
        } catch {
            print("❌ Error cargando parking: \(error)")
            return nil
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

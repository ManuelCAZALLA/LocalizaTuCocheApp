import Foundation
import CoreLocation

final class ParkingStorage {
    static let shared = ParkingStorage()
    private let lastKey = "saved_parking_location"
    private let historyKey = "saved_parking_history"
    private let historyLimit = 20

    // MARK: - Last parking 
    func save(_ parking: ParkingLocation) {
        do {
            let data = try JSONEncoder().encode(parking)
            UserDefaults.standard.set(data, forKey: lastKey)
        } catch {
            print("❌ Error guardando parking: \(error)")
        }
        appendToHistory(parking)
    }

    func load() -> ParkingLocation? {
        guard let data = UserDefaults.standard.data(forKey: lastKey) else { return nil }
        do {
            return try JSONDecoder().decode(ParkingLocation.self, from: data)
        } catch {
            print("❌ Error cargando parking: \(error)")
            return nil
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: lastKey)
    }

    // MARK: - History
    func loadHistory() -> [ParkingLocation] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([ParkingLocation].self, from: data)
        } catch {
            print("❌ Error cargando historial: \(error)")
            return []
        }
    }

    func appendToHistory(_ parking: ParkingLocation) {
        var items = loadHistory()
        items.insert(parking, at: 0)
        if items.count > historyLimit { items = Array(items.prefix(historyLimit)) }
        saveHistory(items)
    }

    func removeFromHistory(id: UUID) {
        var items = loadHistory()
        items.removeAll { $0.id == id }
        saveHistory(items)
    }

    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    private func saveHistory(_ items: [ParkingLocation]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("❌ Error guardando historial: \(error)")
        }
    }
}

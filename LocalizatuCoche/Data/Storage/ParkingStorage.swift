import Foundation
import CoreLocation

final class ParkingStorage {
    static let shared = ParkingStorage()
    private let lastKey = "saved_parking_location"
    private let historyKey = "saved_parking_history"
    private let freeHistoryLimit = 3
    private let fileManager = FileManager.default
    private lazy var storageDirectoryURL: URL = {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let directory = baseURL.appendingPathComponent("ParkingStorage", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }()
    private lazy var lastURL: URL = storageDirectoryURL.appendingPathComponent("\(lastKey).json")
    private lazy var historyURL: URL = storageDirectoryURL.appendingPathComponent("\(historyKey).json")
    
    private init() {
        migrateLegacyStorageIfNeeded()
    }

    // MARK: - Last parking 
    func save(_ parking: ParkingLocation) {
        do {
            let data = try JSONEncoder().encode(parking)
            try writeProtectedData(data, to: lastURL)
        } catch {
            print("❌ Error guardando parking: \(error)")
        }
        appendToHistory(parking)
    }

    func load() -> ParkingLocation? {
        guard let data = try? Data(contentsOf: lastURL) else { return nil }
        do {
            return try JSONDecoder().decode(ParkingLocation.self, from: data)
        } catch {
            print("❌ Error cargando parking: \(error)")
            return nil
        }
    }

    func clear() {
        try? fileManager.removeItem(at: lastURL)
    }

    // MARK: - History
    func loadHistory() -> [ParkingLocation] {
        guard let data = try? Data(contentsOf: historyURL) else { return [] }
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
        if !isProUser, items.count > freeHistoryLimit {
            items = Array(items.prefix(freeHistoryLimit))
        }
        saveHistory(items)
    }

    func removeFromHistory(id: UUID) {
        var items = loadHistory()
        items.removeAll { $0.id == id }
        saveHistory(items)
    }

    func clearHistory() {
        try? fileManager.removeItem(at: historyURL)
    }

    private func saveHistory(_ items: [ParkingLocation]) {
        do {
            let data = try JSONEncoder().encode(items)
            try writeProtectedData(data, to: historyURL)
        } catch {
            print("❌ Error guardando historial: \(error)")
        }
    }

    private func writeProtectedData(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }
    
    private func migrateLegacyStorageIfNeeded() {
        if !fileManager.fileExists(atPath: lastURL.path),
           let legacyLast = UserDefaults.standard.data(forKey: lastKey) {
            try? writeProtectedData(legacyLast, to: lastURL)
            UserDefaults.standard.removeObject(forKey: lastKey)
        }
        
        if !fileManager.fileExists(atPath: historyURL.path),
           let legacyHistory = UserDefaults.standard.data(forKey: historyKey) {
            try? writeProtectedData(legacyHistory, to: historyURL)
            UserDefaults.standard.removeObject(forKey: historyKey)
        }
    }

    private var isProUser: Bool {
        UserDefaults.standard.bool(forKey: "isPro")
    }
}

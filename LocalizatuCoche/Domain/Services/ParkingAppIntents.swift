import AppIntents
import CoreLocation
import Foundation
import UIKit

private enum ProSubscription {
    static var isPro: Bool {
        UserDefaults.standard.bool(forKey: "isPro")
    }
}

private enum ParkingIntentFailure: LocalizedError {
    case proRequired
    case noSavedParking

    var errorDescription: String? {
        switch self {
        case .proRequired:
            return NSLocalizedString("intent_error_pro_required", comment: "")
        case .noSavedParking:
            return NSLocalizedString("intent_error_no_saved_parking", comment: "")
        }
    }
}

@available(iOS 16.0, *)
struct SaveParkingShortcutIntent: AppIntent {
    static let title: LocalizedStringResource = "intent_save_parking_title"

    static let description: IntentDescription = IntentDescription(stringLiteral: "intent_save_parking_description")

    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard ProSubscription.isPro else {
            throw ParkingIntentFailure.proRequired
        }

        let fetcher = OneShotLocationFetcher()
        let location: CLLocation
        do {
            location = try await fetcher.fetchLocation()
        } catch {
            throw error
        }

        let placeName = await reverseGeocodePlaceName(for: location)
        let parking = ParkingLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            date: Date(),
            placeName: placeName,
            note: nil,
            photoData: nil
        )
        ParkingStorage.shared.save(parking)

        let dialog = IntentDialog(stringLiteral: NSLocalizedString("intent_success_saved", comment: ""))
        return .result(dialog: dialog)
    }

    private func reverseGeocodePlaceName(for location: CLLocation) async -> String? {
        await withCheckedContinuation { (cont: CheckedContinuation<String?, Never>) in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                guard let placemark = placemarks?.first else {
                    cont.resume(returning: nil)
                    return
                }
                let name = placemark.name ?? placemark.locality ?? placemark.country
                cont.resume(returning: name)
            }
        }
    }
}

@available(iOS 16.0, *)
struct OpenLastParkingInMapsIntent: AppIntent {
    static let title: LocalizedStringResource = "intent_navigate_parking_title"

    static let description: IntentDescription = IntentDescription(stringLiteral: "intent_navigate_parking_description")

    static var openAppWhenRun: Bool { false }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard ProSubscription.isPro else {
            throw ParkingIntentFailure.proRequired
        }
        guard let parking = ParkingStorage.shared.load() else {
            throw ParkingIntentFailure.noSavedParking
        }

        let url = mapsURL(for: parking)
        await MainActor.run {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

        let dialog = IntentDialog(stringLiteral: NSLocalizedString("intent_success_opening_maps", comment: ""))
        return .result(dialog: dialog)
    }

    private func mapsURL(for parking: ParkingLocation) -> URL {
        let queryName = (parking.placeName ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://maps.apple.com/?ll=\(parking.latitude),\(parking.longitude)\(queryName.isEmpty ? "" : "&q=\(queryName)")"
        return URL(string: urlString) ?? URL(string: "http://maps.apple.com/")!
    }
}

@available(iOS 16.0, *)
struct ParkingAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SaveParkingShortcutIntent(),
            phrases: [
                "Save parking in \(.applicationName)",
                "Guardar aparcamiento en \(.applicationName)",
                "Save my parking spot in \(.applicationName)",
                "Guardar mi aparcamiento en \(.applicationName)"
            ],
            shortTitle: "intent_short_title_save",
            systemImageName: "parkingsign.circle"
        )
        AppShortcut(
            intent: OpenLastParkingInMapsIntent(),
            phrases: [
                "Navigate to my car in \(.applicationName)",
                "Ir a mi coche con \(.applicationName)",
                "Open parking in Maps with \(.applicationName)",
                "Abrir aparcamiento en Mapas con \(.applicationName)"
            ],
            shortTitle: "intent_short_title_navigate",
            systemImageName: "map"
        )
    }
}

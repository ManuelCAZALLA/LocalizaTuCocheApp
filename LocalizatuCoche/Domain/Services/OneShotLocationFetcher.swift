import CoreLocation
import Foundation

/// Obtiene una única lectura de ubicación para atajos / Siri (App Intents).
final class OneShotLocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var timeoutTask: Task<Void, Never>?

    private enum FetchError: LocalizedError {
        case denied
        case restricted
        case timeout

        var errorDescription: String? {
            switch self {
            case .denied, .restricted:
                return NSLocalizedString("intent_error_location_denied", comment: "")
            case .timeout:
                return NSLocalizedString("intent_error_no_location", comment: "")
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func fetchLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let status = manager.authorizationStatus
            switch status {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied:
                continuation.resume(throwing: FetchError.denied)
                self.continuation = nil
                return
            case .restricted:
                continuation.resume(throwing: FetchError.restricted)
                self.continuation = nil
                return
            @unknown default:
                continuation.resume(throwing: FetchError.denied)
                self.continuation = nil
                return
            }

            timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard let self else { return }
                if self.continuation != nil {
                    self.continuation?.resume(throwing: FetchError.timeout)
                    self.continuation = nil
                }
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied:
            continuation?.resume(throwing: FetchError.denied)
            continuation = nil
            timeoutTask?.cancel()
        case .restricted:
            continuation?.resume(throwing: FetchError.restricted)
            continuation = nil
            timeoutTask?.cancel()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        continuation?.resume(returning: location)
        continuation = nil
        timeoutTask?.cancel()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        timeoutTask?.cancel()
    }
}

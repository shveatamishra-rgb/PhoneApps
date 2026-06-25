import CoreLocation
import Foundation

/// Provides the device location for the Panchang sunrise/sunset calculation.
///
/// Privacy: the coordinates are used **only on-device** to compute the Panchang —
/// they are never reverse-geocoded, transmitted, or stored off-device — so the
/// app's "Data Not Collected" posture holds. A bundled city list is the fallback
/// when location permission is denied or the user prefers a manual choice.
@MainActor
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    private static let useGPSKey = "panchangUseGPS"

    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?
    @Published var useGPS: Bool {
        didSet { UserDefaults.standard.set(useGPS, forKey: Self.useGPSKey) }
    }

    /// Bumped on each location update so views can recompute cheaply via onChange.
    @Published private(set) var revision = 0

    override init() {
        authorization = manager.authorizationStatus
        useGPS = UserDefaults.standard.bool(forKey: Self.useGPSKey)
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // city-level is plenty
        if useGPS, authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            manager.requestLocation()
        }
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }
    var isDenied: Bool {
        authorization == .denied || authorization == .restricted
    }
    var isActive: Bool { useGPS && location != nil }

    func enableGPS() {
        useGPS = true
        switch authorization {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: break // denied/restricted — the UI guides the user to Settings
        }
    }

    func useManualCity() {
        useGPS = false
        location = nil
    }

    /// The City to feed the Panchang engine: a GPS-derived place when active,
    /// otherwise the manually-selected city. `nil` when the user hasn't chosen a
    /// location yet (no GPS and no manual city) — the UI then prompts to select.
    func activeCity(manualID: String, lang: Lang) -> City? {
        if useGPS, let loc = location {
            return City(
                id: "current", nameEN: "My Location", nameHI: "मेरा स्थान", regionEN: "",
                latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude,
                timeZoneID: TimeZone.current.identifier
            )
        }
        guard !manualID.isEmpty else { return nil }
        return Cities.byID(manualID)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorization = manager.authorizationStatus
            if useGPS, isAuthorized { manager.requestLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            location = loc
            revision += 1
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

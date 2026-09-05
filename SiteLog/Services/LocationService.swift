import CoreLocation
import Foundation
import Observation

struct LocationFix {
    let coordinate: CLLocationCoordinate2D
    let label: String?
}

/// One-shot "where am I right now" helper used when a visit starts.
/// Requests when-in-use permission on first use and never tracks in the background.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @ObservationIgnored private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isDenied: Bool {
        switch manager.authorizationStatus {
        case .denied, .restricted: return true
        default: return false
        }
    }

    /// Returns a coordinate plus a short place label, or nil if the user
    /// declined permission or no fix arrived.
    func currentFix() async -> LocationFix? {
        guard let location = await requestLocation() else { return nil }
        let label = await reverseGeocode(location)
        return LocationFix(coordinate: location.coordinate, label: label)
    }

    private func requestLocation() async -> CLLocation? {
        if isDenied { return nil }
        if continuation != nil { return nil } // a request is already in flight

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            switch self.manager.authorizationStatus {
            case .notDetermined:
                self.manager.requestWhenInUseAuthorization()
                // requestLocation() is issued from the authorization callback.
            default:
                self.manager.requestLocation()
            }
        }
    }

    private func finish(with location: CLLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }

    private func reverseGeocode(_ location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        guard let place = try? await geocoder.reverseGeocodeLocation(location).first else { return nil }
        let parts = [place.thoroughfare ?? place.name, place.locality].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard self.continuation != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .denied, .restricted:
                self.finish(with: nil)
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latest = locations.last
        Task { @MainActor in self.finish(with: latest) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(with: nil) }
    }
}

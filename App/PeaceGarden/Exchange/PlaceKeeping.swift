import CoreLocation
import Foundation
import Observation
import SeedCore

/// Whether this person is willing for a meeting to be recorded with a location,
/// and the one reading taken when they are.
///
/// Two separate questions, deliberately. The standing setting says the option
/// may be offered; it does not say it happens. Each meeting is still decided on
/// its own, because willingness at a conference is not willingness outside your
/// own front door, and a switch set once months ago cannot tell the difference.
///
/// Nothing here transmits. The reading is taken on this phone and stays on it:
/// see `ExchangeProtocol`, where the wire has no field for a location at all.
/// The other person's agreement is needed all the same, because two people at
/// one meeting are standing in the same place.
@Observable
@MainActor
final class PlaceKeeping: NSObject {
    /// The standing setting, off until somebody turns it on.
    ///
    /// Kept here rather than in `Identity` because it is a preference of this
    /// phone rather than a property of the seed, and a seed must stay derivable
    /// from thirty-two bytes and a birthday.
    private(set) var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.settingKey) }
    }

    /// Whether the Meet screen has already offered this, so that somebody who
    /// said no is not asked again every time they open it.
    private(set) var hasBeenOffered: Bool {
        didSet { UserDefaults.standard.set(hasBeenOffered, forKey: Self.offeredKey) }
    }

    private static let settingKey = "place.enabled.v1"
    private static let offeredKey = "place.offered.v1"

    private let manager = CLLocationManager()
    private var pending: [CheckedContinuation<Coordinate?, Never>] = []

    override init() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.bool(forKey: Self.settingKey)
        hasBeenOffered = defaults.bool(forKey: Self.offeredKey)
        super.init()
        manager.delegate = self
        // Ten metres is finer than the exchange needs and coarse enough not to
        // wait for a fix that will not arrive indoors.
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// Whether the option is worth putting in front of somebody.
    ///
    /// False once they have been asked and declined. The Meet screen offers it
    /// rather than demanding it, and an offer repeated at every meeting is not
    /// an offer.
    var shouldOffer: Bool { !isEnabled && !hasBeenOffered }

    /// Whether this phone can actually supply a reading.
    ///
    /// The setting alone is not enough: iOS can revoke the permission from
    /// Settings at any time, and a switch that lies about what it will do is
    /// worse than no switch.
    var canProvide: Bool {
        guard isEnabled else { return false }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return true
        default: return false
        }
    }

    func declineOffer() {
        hasBeenOffered = true
    }

    /// Turn it on, asking iOS for permission the first time.
    ///
    /// This is the only place the system prompt can appear, and it is reached
    /// only from a person tapping to accept the offer. Nothing asks in the
    /// background, and nothing asks during a meeting.
    func enable() {
        hasBeenOffered = true
        isEnabled = true
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func disable() {
        isEnabled = false
    }

    /// One reading, or nothing.
    ///
    /// Nothing is a perfectly good answer: indoors, with the permission revoked,
    /// or simply not settled in time. The meeting then keeps its figurative
    /// place, which is the same outcome as declining, and no worse a record.
    func reading() async -> Coordinate? {
        guard canProvide else { return nil }
        return await withCheckedContinuation { continuation in
            pending.append(continuation)
            manager.requestLocation()
        }
    }

    private func settle(_ coordinate: Coordinate?) {
        let waiting = pending
        pending = []
        for continuation in waiting { continuation.resume(returning: coordinate) }
    }
}

extension PlaceKeeping: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let last = locations.last.map {
            Coordinate(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude
            )
        }
        Task { @MainActor [weak self] in self?.settle(last) }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in self?.settle(nil) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Somebody may have refused at the system prompt, or revoked it later in
        // Settings. The standing switch follows what iOS actually permits, so it
        // never claims more than it can do.
        //
        // The status is read here rather than inside the hop: `CLLocationManager`
        // is not `Sendable`, and carrying it to the main actor is the data race
        // the compiler is right to refuse. A status value travels safely.
        let refused = switch manager.authorizationStatus {
        case .denied, .restricted: true
        default: false
        }
        guard refused else { return }
        Task { @MainActor [weak self] in self?.disable() }
    }
}

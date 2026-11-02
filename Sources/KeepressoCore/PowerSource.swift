import Foundation
import SystemObservations

/// Abstraction over the IOKit power-source API (`IOPowerSources`) so trigger
/// logic can be unit-tested without real hardware state.
///
/// Mirrors the ``PowerAsserting`` seam: ``IOKitPowerSourceMonitor`` is the real
/// backend; tests inject a fake that returns canned snapshots.
public protocol PowerSourceMonitoring: AnyObject {
    /// The power situation right now. Reading is cheap; callers may poll it.
    var current: PowerSourceSnapshot { get }
}

/// Real implementation backed by the shared IOKit power-source reader.
///
/// Not thread-safe by design, read it from the main actor alongside the
/// owning controller, the same way ``IOKitPowerAssertionManager`` is used.
public final class IOKitPowerSourceMonitor: PowerSourceMonitoring {
    private let reader: PowerSourceObserving

    public convenience init() {
        self.init(reader: IOKitPowerSourceReader())
    }

    init(reader: PowerSourceObserving) {
        self.reader = reader
    }

    public var current: PowerSourceSnapshot {
        switch reader.observe(at: Date()) {
        case .available(let snapshot, _): return snapshot
        case .unavailable:
            // Compatibility fallback only: U PowerSource.swift:57-59. Keepresso
            // has no unavailable sample in its original monitor interface.
            return PowerSourceSnapshot(provider: .unknown, isCharging: false, hasBattery: false)
        }
    }
}

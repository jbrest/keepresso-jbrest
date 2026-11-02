import Foundation
import SystemObservations

/// Existing Keepresso injection seam. Shared readers expose availability;
/// this product adapter retains the original snapshot-only interface.
public protocol PowerSourceMonitoring: AnyObject {
    var current: PowerSourceSnapshot { get }
}

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

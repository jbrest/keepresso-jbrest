// Adapted from KeepressoCore/PowerSource.swift, upstream 7ea73a6.
import Foundation
import IOKit.ps
import RuleModel

public protocol PowerSourceObserving: AnyObject {
    func observe(at time: Date) -> SignalObservation<PowerSourceSnapshot>
}

/// Acquisition only. Each observation owns its IOKit results locally; hosts
/// supply time and decide how missing or partially known readings are used.
public final class IOKitPowerSourceReader: PowerSourceObserving {
    private let read: () -> PowerSourceSnapshot?

    public convenience init() {
        self.init(read: Self.readSnapshot)
    }

    init(read: @escaping () -> PowerSourceSnapshot?) {
        self.read = read
    }

    public func observe(at time: Date) -> SignalObservation<PowerSourceSnapshot> {
        guard let snapshot = read() else {
            return .unavailable(reason: .readFailed, attemptedAt: time)
        }
        return .available(value: snapshot, observedAt: time)
    }

    private static func readSnapshot() -> PowerSourceSnapshot? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return nil
        }

        // System-wide provider (AC vs battery), independent of how many sources
        // are attached.
        let provider: PowerSourceSnapshot.Provider
        switch IOPSGetProvidingPowerSourceType(blob)?.takeUnretainedValue() as String? {
        case kIOPSACPowerValue: provider = .ac
        case kIOPSBatteryPowerValue: provider = .battery
        default: provider = .unknown
        }

        // Walk the individual sources to learn about the battery, if any.
        var hasBattery = false
        var isCharging = false
        var percentage: Int?
        let sources = IOPSCopyPowerSourcesList(blob).takeRetainedValue() as [CFTypeRef]
        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue()
                    as? [String: Any] else { continue }
            hasBattery = true
            if let charging = desc[kIOPSIsChargingKey] as? Bool, charging {
                isCharging = true
            }
            if let current = desc[kIOPSCurrentCapacityKey] as? Int,
               let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0 {
                percentage = Int((Double(current) / Double(max) * 100).rounded())
            }
        }

        return PowerSourceSnapshot(
            provider: provider, isCharging: isCharging, hasBattery: hasBattery, percentage: percentage
        )
    }
}

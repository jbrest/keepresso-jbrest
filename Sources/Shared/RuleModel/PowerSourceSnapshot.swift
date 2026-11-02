// Adapted from KeepressoCore/PowerSource.swift, upstream 7ea73a6.
import Foundation

/// A point-in-time reading of the Mac's power situation.
///
/// Deliberately small and value-typed so triggers can be evaluated as pure
/// functions of a snapshot in tests.
public struct PowerSourceSnapshot: Equatable, Sendable {
    /// What is currently powering the machine.
    public enum Provider: String, Codable, Sendable {
        /// Running on wall/AC power (or any external adapter).
        case ac
        /// Running on the internal battery.
        case battery
        /// Could not be determined; products choose how to handle this value.
        case unknown
    }

    /// The power source currently providing power to the system.
    public var provider: Provider

    /// Whether an internal battery is present *and* actively charging.
    public var isCharging: Bool

    /// Whether the machine reports any battery at all (false on most desktops).
    public var hasBattery: Bool

    /// Current charge as a percentage of full capacity (0–100), or `nil` when
    /// ``hasBattery`` is false or the reading isn't available.
    public var percentage: Int?

    public init(provider: Provider, isCharging: Bool, hasBattery: Bool, percentage: Int? = nil) {
        self.provider = provider
        self.isCharging = isCharging
        self.hasBattery = hasBattery
        self.percentage = percentage
    }
}


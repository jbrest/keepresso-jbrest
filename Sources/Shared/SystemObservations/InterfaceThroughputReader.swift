// Adapted from KeepressoCore/NetworkThroughput.swift:30-100, upstream 7ea73a6.
import Foundation
import RuleModel

public protocol ThroughputObserving: AnyObject {
    func observe() -> SignalObservation<Double>
}

public final class InterfaceThroughputReader: ThroughputObserving {
    private var previous: (bytes: UInt64, at: Date)?
    private let ttl: TimeInterval
    private let now: () -> Date
    private let readBytes: () -> UInt64?
    /// Built lazily on first read (the probe reads `self`), holding `self`
    /// unowned: the cache and this reader share a lifetime.
    private lazy var cache = TTLCache<SignalObservation<Double>>(ttl: ttl, now: now) { [unowned self] in
        self.readThroughputDelta()
    }

    public convenience init() {
        self.init(readBytes: Self.interfaceBytes)
    }

    /// The byte source and clock are injectable so the delta and TTL logic can
    /// be unit-tested without real interface counters.
    public init(
        ttl: TimeInterval = 0.5,
        now: @escaping () -> Date = Date.init,
        readBytes: @escaping () -> UInt64?
    ) {
        self.ttl = ttl
        self.now = now
        self.readBytes = readBytes
    }

    public func observe() -> SignalObservation<Double> { cache.current }

    private func readThroughputDelta() -> SignalObservation<Double> {
        guard let bytes = readBytes() else {
            return .unavailable(reason: .readFailed, attemptedAt: now())
        }
        let at = now()
        defer { previous = (bytes, at) }
        // A backwards counter means an interface reset or a 32-bit wrap (the
        // per-interface counters are 32-bit): skip that one interval rather than
        // report a bogus negative rate. The product decides how to handle unavailable data.
        guard let previous else { return .unavailable(reason: .insufficientData, attemptedAt: at) }
        guard bytes >= previous.bytes else { return .unavailable(reason: .invalidData, attemptedAt: at) }
        let elapsed = at.timeIntervalSince(previous.at)
        guard elapsed > 0 else { return .unavailable(reason: .invalidData, attemptedAt: at) }
        return .available(value: Double(bytes - previous.bytes) / elapsed, observedAt: at)
    }

    /// Sum of in + out bytes across every non-loopback interface. Deliberately
    /// sums all of them (physical, VPN, bridge): the goal is a rough "is a large
    /// transfer running" gauge, and the threshold plus hysteresis absorb the
    /// double-counting a tunnel-over-physical setup introduces.
    private static func interfaceBytes() -> UInt64? {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return nil }
        defer { freeifaddrs(head) }
        var total: UInt64 = 0
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let entry = cursor {
            defer { cursor = entry.pointee.ifa_next }
            // Only the link-layer (AF_LINK) row of each interface carries the
            // if_data byte counters.
            guard let addr = entry.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            guard entry.pointee.ifa_flags & UInt32(IFF_LOOPBACK) == 0 else { continue }
            guard let data = entry.pointee.ifa_data else { continue }
            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            total += UInt64(stats.ifi_ibytes) + UInt64(stats.ifi_obytes)
        }
        return total
    }
}


import Foundation

/// Abstraction over the machine's overall network throughput so a transfer
/// trigger can be tested with scripted readings. Mirrors ``CPULoadReading``.
public protocol NetworkThroughputReading: AnyObject {
    /// Combined in + out throughput across the physical interfaces since the
    /// previous call, in bytes per second, or `nil` when no reading is available
    /// yet (first call, a failed read, or a counter that went backwards).
    func currentBytesPerSecond() -> Double?
}

/// Friendly rendering of a KB/s threshold, shared by the rule label and the
/// picker so both read the same ("500 KB/s", "1 MB/s").
public enum NetworkThroughput {
    public static func rateLabel(kilobytesPerSecond kb: Int) -> String {
        guard kb >= 1024 else { return "\(kb) KB/s" }
        if kb % 1024 == 0 { return "\(kb / 1024) MB/s" }
        let mb = (Double(kb) / 1024 * 10).rounded() / 10
        return "\(mb) MB/s"
    }
}

/// Real backend over `getifaddrs` interface byte counters. Throughput is the
/// byte delta between consecutive calls divided by the elapsed time, so the
/// first call returns `nil` (a since-boot total would be meaningless here).
///
/// Cached briefly like ``HostCPULoadReader``: the trigger engine and the menu's
/// live rule list both evaluate within the same tick, and a back-to-back delta
/// would be over a meaninglessly tiny interval.
public final class GetifaddrsThroughputReader: NetworkThroughputReading {
    private let reader: InterfaceThroughputReader

    public init() { reader = InterfaceThroughputReader() }

    /// The byte source and clock are injectable so the delta and TTL logic can
    /// be unit-tested without real interface counters.
    init(ttl: TimeInterval = 0.5, now: @escaping () -> Date = Date.init,
         readBytes: @escaping () -> UInt64?) {
        reader = InterfaceThroughputReader(ttl: ttl, now: now, readBytes: readBytes)
    }

    public func currentBytesPerSecond() -> Double? {
        switch reader.observe() {
        case .available(let rate, _): return rate
        case .unavailable: return nil
        }
    }
}

/// Fires while overall network throughput sits above a threshold: a large
/// download, upload, or sync is running, so the Mac should stay awake even when
/// no single app or process rule fits.
///
/// Raw per-second throughput is bursty, so the decision runs on an exponential
/// moving average (a brief burst doesn't start a session) with hysteresis (once
/// on, it takes a clear drop below the threshold to turn off, so a transfer
/// hovering at the threshold doesn't flap). The state transition is a pure
/// function (``step(_:sampleBytesPerSecond:thresholdKilobytesPerSecond:)``) for
/// direct unit testing. Mirrors ``CPULoadTrigger``.
public final class NetworkThroughputTrigger: Trigger {
    /// Throughput (in KB/s, 1 KB = 1024 bytes) the smoothed rate must reach.
    public var thresholdKilobytesPerSecond: Int

    /// Smoothing weight of each new sample; ~0.25 at one sample per second means
    /// a sustained transfer settles in a few seconds.
    static let alpha = ThroughputThresholdEvaluation.alpha
    /// Fraction of the threshold the average must fall below to turn off again.
    /// A relative band (unlike CPU's absolute one) since throughput is unbounded.
    static let releaseFraction = ThroughputThresholdEvaluation.releaseFraction

    public struct SmoothingState: Equatable, Sendable {
        /// The smoothed rate in bytes per second.
        public var average: Double?
        public var isSatisfied = false
        public init() {}
    }

    private let reader: NetworkThroughputReading
    private var state = SmoothingState()

    public init(thresholdKilobytesPerSecond: Int, reader: NetworkThroughputReading = GetifaddrsThroughputReader()) {
        self.thresholdKilobytesPerSecond = thresholdKilobytesPerSecond
        self.reader = reader
    }

    public var label: String {
        L("Network above %@", NetworkThroughput.rateLabel(kilobytesPerSecond: thresholdKilobytesPerSecond))
    }

    /// Advance the smoothing average by one reading. Done here (not in
    /// ``isSatisfied()``) so the EMA steps exactly once per reconcile even while
    /// the menu's live rule list is reading the trigger (the E6 double-step).
    public func tick() {
        state = Self.step(
            state,
            sampleBytesPerSecond: reader.currentBytesPerSecond(),
            thresholdKilobytesPerSecond: thresholdKilobytesPerSecond
        )
    }

    public func isSatisfied() -> Bool { state.isSatisfied }

    /// Pure decision step, exposed for direct unit testing. A `nil` sample
    /// (failed read / counter wrap) keeps the previous average and verdict
    /// rather than dropping an active session on a transient hiccup.
    static func step(_ state: SmoothingState, sampleBytesPerSecond sample: Double?, thresholdKilobytesPerSecond: Int) -> SmoothingState {
        var shared = ThroughputThresholdState()
        shared.average = state.average
        shared.isSatisfied = state.isSatisfied
        let next: ThroughputThresholdState
        if let sample {
            next = ThroughputThresholdEvaluation.step(shared, sampleBytesPerSecond: sample,
                                                      thresholdKilobytesPerSecond: thresholdKilobytesPerSecond)
        } else {
            // Compatibility behavior: reevaluate retained data against current
            // settings after failed reads (U NetworkThroughput.swift:147-174).
            next = ThroughputThresholdEvaluation.reevaluate(shared,
                                                            thresholdKilobytesPerSecond: thresholdKilobytesPerSecond)
        }
        var result = SmoothingState()
        result.average = next.average
        result.isSatisfied = next.isSatisfied
        return result
    }
}

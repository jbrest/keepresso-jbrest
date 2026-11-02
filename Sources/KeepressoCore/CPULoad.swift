import Foundation
import SystemObservations

/// Abstraction over the machine's overall CPU usage so a load trigger can be
/// tested with scripted readings. Mirrors the other monitor seams.
public protocol CPULoadReading: AnyObject {
    /// Overall CPU usage since the previous call, as a fraction (0...1), or
    /// `nil` when no reading is available yet (first call, or a failed read).
    func currentLoad() -> Double?
}

/// Real backend over Mach's `host_statistics` CPU tick counters. Usage is the
/// busy-tick share of the delta between consecutive calls, so the first call
/// returns `nil` (a since-boot average would be meaningless here).
///
/// Readings are cached briefly: the trigger engine and the menu's live rule
/// list each evaluate within the same tick, and back-to-back delta reads
/// would give the second caller a meaninglessly tiny interval.
public final class HostCPULoadReader: CPULoadReading {
    /// One cumulative sample of the host's CPU tick counters.
    struct Ticks: Equatable {
        var busy: UInt64
        var total: UInt64
    }

    private let reader: CPUUsageObserving

    public convenience init() {
        self.init(reader: MachCPUUsageReader())
    }

    private init(reader: CPUUsageObserving) {
        self.reader = reader
    }

    /// The tick source and clock are injectable so the delta and TTL logic can
    /// be unit-tested without real hardware counters.
    init(
        ttl: TimeInterval = 0.5,
        now: @escaping () -> Date = Date.init,
        readTicks: @escaping () -> Ticks?
    ) {
        self.reader = MachCPUUsageReader(ttl: ttl, now: now, readCounters: {
            readTicks().map { CPUCounterSample(busy: $0.busy, total: $0.total) }
        })
    }

    public func currentLoad() -> Double? {
        switch reader.observe() {
        case .available(let fraction, _): return fraction
        case .unavailable: return nil
        }
    }
}

/// Fires while overall CPU usage sits above a threshold: a build, render, or
/// training run is working, so the Mac should stay awake.
///
/// Raw per-second usage is spiky, so the decision runs on an exponential
/// moving average (a brief spike doesn't start a session) with hysteresis
/// (once on, it takes a dip clearly below the threshold to turn off, so usage
/// hovering at the threshold doesn't flap). The state transition is a pure
/// function (``step(_:sample:thresholdPercent:)``) for direct unit testing.
public final class CPULoadTrigger: Trigger {
    /// Percentage (1...100) the smoothed usage must reach.
    public var thresholdPercent: Int

    /// Smoothing weight of each new sample; ~0.25 at one sample per second
    /// means a sustained change settles in a few seconds.
    static let alpha = CPUThresholdEvaluation.alpha
    /// How far (as a fraction) the average must fall below the threshold to
    /// turn off again.
    static let hysteresis = CPUThresholdEvaluation.hysteresis

    public struct SmoothingState: Equatable, Sendable {
        public var average: Double?
        public var isSatisfied = false
        public init() {}
    }

    private let reader: CPULoadReading
    // Mixed state: smoothing/hysteresis is operational; failed-read reevaluation
    // of its retained average preserves U CPULoad.swift:124-153 (S2/S4).
    private var state = SmoothingState()

    public init(thresholdPercent: Int, reader: CPULoadReading = HostCPULoadReader()) {
        self.thresholdPercent = thresholdPercent
        self.reader = reader
    }

    public var label: String { L("CPU above %d%%", thresholdPercent) }

    /// Advance the smoothing average by one reading. Done here (not in
    /// ``isSatisfied()``) so the EMA steps exactly once per reconcile: the menu's
    /// live rule list also reads this trigger, and stepping on every read would
    /// double the effective smoothing rate whenever the menu is open.
    public func tick() {
        state = Self.step(state, sample: reader.currentLoad(), thresholdPercent: thresholdPercent)
    }

    public func isSatisfied() -> Bool { state.isSatisfied }

    /// Pure decision step, exposed for direct unit testing. A `nil` sample
    /// (failed read) keeps the previous average and verdict rather than
    /// dropping an active session on a transient hiccup.
    static func step(_ state: SmoothingState, sample: Double?, thresholdPercent: Int) -> SmoothingState {
        var shared = CPUThresholdState()
        shared.average = state.average
        shared.isSatisfied = state.isSatisfied
        let next: CPUThresholdState
        if let sample {
            next = CPUThresholdEvaluation.step(shared, sample: sample, thresholdPercent: thresholdPercent)
        } else {
            next = CPUThresholdEvaluation.reevaluate(shared, thresholdPercent: thresholdPercent)
        }
        var result = SmoothingState()
        result.average = next.average
        result.isSatisfied = next.isSatisfied
        return result
    }
}

// Adapted from KeepressoCore/CPULoad.swift:18-77, upstream 7ea73a6.
import Foundation
import RuleModel

public protocol CPUUsageObserving: AnyObject {
    func observe() -> SignalObservation<Double>
}

/// Stateful counter acquisition with the original short TTL. Drive each reader
/// from one execution context; thread isolation remains a host responsibility.
public final class MachCPUUsageReader: CPUUsageObserving {
    private var previous: CPUCounterSample?
    private let now: () -> Date
    private let read: () -> CPUCounterSample?
    private lazy var cache = TTLCache<SignalObservation<Double>>(ttl: ttl, now: now) { [unowned self] in
        self.readDelta()
    }
    private let ttl: TimeInterval

    public convenience init() {
        self.init(readCounters: Self.readCounters)
    }

    public init(
        ttl: TimeInterval = 0.5,
        now: @escaping () -> Date = Date.init,
        readCounters: @escaping () -> CPUCounterSample?
    ) {
        self.ttl = ttl
        self.now = now
        self.read = readCounters
    }

    public func observe() -> SignalObservation<Double> { cache.current }

    private func readDelta() -> SignalObservation<Double> {
        let time = now()
        guard let counters = read() else {
            return .unavailable(reason: .readFailed, attemptedAt: time)
        }
        defer { previous = counters }
        guard let previous else {
            return .unavailable(reason: .insufficientData, attemptedAt: time)
        }
        guard counters.total > previous.total else {
            return .unavailable(reason: .invalidData, attemptedAt: time)
        }
        let fraction = Double(counters.busy - previous.busy) / Double(counters.total - previous.total)
        return .available(value: fraction, observedAt: time)
    }

    private static func readCounters() -> CPUCounterSample? {
        var size = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        var info = host_cpu_load_info_data_t()
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        // cpu_ticks lanes: 0 = user, 1 = system, 2 = idle, 3 = nice.
        let busy = UInt64(info.cpu_ticks.0) + UInt64(info.cpu_ticks.1) + UInt64(info.cpu_ticks.3)
        return CPUCounterSample(busy: busy, total: busy + UInt64(info.cpu_ticks.2))
    }
}

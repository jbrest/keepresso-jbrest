import Foundation
import Testing
import RuleModel
import SystemObservations

@Test func sharedCPUReaderReportsBaselineFailureAndCounterResetSeparately() {
    var time = Date(timeIntervalSince1970: 0)
    var sample: CPUCounterSample? = .init(busy: 10, total: 100)
    let reader = MachCPUUsageReader(ttl: 0.5, now: { time }, readCounters: { sample })
    #expect(reader.observe() == .unavailable(reason: .insufficientData, attemptedAt: time))
    time = time.addingTimeInterval(1)
    sample = nil
    #expect(reader.observe() == .unavailable(reason: .readFailed, attemptedAt: time))
    time = time.addingTimeInterval(1)
    sample = .init(busy: 20, total: 200)
    #expect(reader.observe() == .available(value: 0.1, observedAt: time))
    time = time.addingTimeInterval(1)
    sample = .init(busy: 10, total: 100)
    #expect(reader.observe() == .unavailable(reason: .invalidData, attemptedAt: time))
}

@Test func sharedTTLCacheRetainsNilAndUsesTheExactExpiryBoundary() {
    var time = Date(timeIntervalSince1970: 0)
    var calls = 0
    let cache = TTLCache<Int?>(ttl: 1, now: { time }) { calls += 1; return nil }
    #expect(cache.current == nil)
    time = time.addingTimeInterval(0.999)
    #expect(cache.current == nil)
    #expect(calls == 1)
    time = time.addingTimeInterval(0.001)
    #expect(cache.current == nil)
    #expect(calls == 2)
}

@Test func realCPUReaderReadOnlySmoke() {
    switch MachCPUUsageReader().observe() {
    case .available(let value, _): print("CPU reader smoke: available fraction=\(value)")
    case .unavailable(let reason, _):
        #expect(reason == .insufficientData)
        print("CPU reader smoke: unavailable reason=\(reason)")
    }
}

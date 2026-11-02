import Foundation
import Testing
import RuleModel
import SystemObservations

@Test func throughputReaderSeparatesFailureResetAndZeroElapsedTime() {
    var time = Date(timeIntervalSince1970: 0)
    var bytes: UInt64? = 100
    let reader = InterfaceThroughputReader(ttl: 0, now: { time }, readBytes: { bytes })
    #expect(reader.observe() == .unavailable(reason: .insufficientData, attemptedAt: time))
    bytes = 200
    #expect(reader.observe() == .unavailable(reason: .invalidData, attemptedAt: time))
    time = time.addingTimeInterval(2)
    bytes = 400
    #expect(reader.observe() == .available(value: 100, observedAt: time))
    time = time.addingTimeInterval(1)
    bytes = nil
    #expect(reader.observe() == .unavailable(reason: .readFailed, attemptedAt: time))
    time = time.addingTimeInterval(1)
    bytes = 10
    #expect(reader.observe() == .unavailable(reason: .invalidData, attemptedAt: time))
    time = time.addingTimeInterval(1)
    bytes = 10
    #expect(reader.observe() == .available(value: 0, observedAt: time))
}

@Test func realThroughputReaderReadOnlySmoke() {
    let first = InterfaceThroughputReader().observe()
    guard case .unavailable(let reason, _) = first else {
        Issue.record("First throughput sample must establish a baseline")
        return
    }
    #expect(reason == .insufficientData)
    print("Throughput reader smoke: unavailable reason=\(reason)")
}

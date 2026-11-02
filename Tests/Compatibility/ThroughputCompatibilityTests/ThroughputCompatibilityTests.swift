import Foundation
import Testing
@testable import KeepressoCore

private func legacy(_ state: NetworkThroughputTrigger.SmoothingState, sample: Double?,
                    thresholdKilobytesPerSecond: Int) -> NetworkThroughputTrigger.SmoothingState {
        var next = state
        // A non-positive threshold is malformed (the picker never makes one).
        // Treat it as "never satisfied" instead of the always-true it would
        // otherwise compute (average >= 0), so a corrupt or imported rule can't
        // pin the Mac awake with nothing able to release it.
        guard thresholdKilobytesPerSecond > 0 else {
            next.average = nil
            next.isSatisfied = false
            return next
        }
        if let sample {
            let clamped = max(sample, 0)
            next.average = state.average.map { $0 + 0.25 * (clamped - $0) } ?? clamped
        }
        guard let average = next.average else {
            next.isSatisfied = false
            return next
        }
        let on = Double(thresholdKilobytesPerSecond) * 1024
        let off = on * 0.7
        next.isSatisfied = state.isSatisfied ? average >= off : average >= on
        return next
}

@Test func throughputAdapterMatchesUpstreamSequence() {
    var expected = NetworkThroughputTrigger.SmoothingState()
    var actual = expected
    let samples: [Double?] = [nil, 200_000, nil, 0, -1, 1_000_000, nil, 30_000]
    for threshold in [100, 200, 1, 0, -1, Int.max] {
        for sample in samples {
            expected = legacy(expected, sample: sample, thresholdKilobytesPerSecond: threshold)
            actual = NetworkThroughputTrigger.step(actual, sampleBytesPerSecond: sample,
                                                    thresholdKilobytesPerSecond: threshold)
            #expect(actual == expected)
        }
    }
}

@Test func throughputAdapterRetainsCounterBaselineAcrossFailure() {
    var time = Date(timeIntervalSince1970: 0)
    var bytes: UInt64? = 100
    var calls = 0
    let reader = GetifaddrsThroughputReader(now: { time }, readBytes: { calls += 1; return bytes })
    #expect(reader.currentBytesPerSecond() == nil)
    bytes = 200
    #expect(reader.currentBytesPerSecond() == nil)
    #expect(calls == 1)
    time = time.addingTimeInterval(1)
    bytes = nil
    #expect(reader.currentBytesPerSecond() == nil)
    time = time.addingTimeInterval(1)
    bytes = 500
    #expect(reader.currentBytesPerSecond() == 200)
    time = time.addingTimeInterval(1)
    bytes = 10
    #expect(reader.currentBytesPerSecond() == nil)
    time = time.addingTimeInterval(1)
    bytes = 110
    #expect(reader.currentBytesPerSecond() == 100)
}

import Foundation
import Testing
@testable import KeepressoCore

private func legacyCPUStep(_ state: CPULoadTrigger.SmoothingState, sample: Double?, threshold: Int) -> CPULoadTrigger.SmoothingState {
    // Original U CPULoad.swift:127-153, independent compatibility oracle.
    var next = state
    guard threshold > 0 else { next.average = nil; next.isSatisfied = false; return next }
    if let sample {
        let clamped = min(max(sample, 0), 1)
        next.average = state.average.map { $0 + 0.25 * (clamped - $0) } ?? clamped
    }
    guard let average = next.average else { next.isSatisfied = false; return next }
    let on = Double(threshold) / 100
    let off = max(on - 0.05, on * 0.5)
    next.isSatisfied = state.isSatisfied ? average >= off : average >= on
    return next
}

@Test func cpuAdapterMatchesUpstreamForChangingThresholdsAndMissingSamples() {
    var actual = CPULoadTrigger.SmoothingState()
    var expected = actual
    for (sample, threshold) in [(Double?.none, 50), (0.8, 50), (nil, 95), (nil, 20), (0.0, 20), (nil, 0), (1.2, 5), (-0.2, 5), (nil, 101)] {
        actual = CPULoadTrigger.step(actual, sample: sample, thresholdPercent: threshold)
        expected = legacyCPUStep(expected, sample: sample, threshold: threshold)
        #expect(actual == expected)
    }
}

private final class ScriptedCPU: CPULoadReading {
    var readings: [Double?] = [0.8, nil, nil]
    var reads = 0
    func currentLoad() -> Double? { reads += 1; return readings.removeFirst() }
}

@Test func cpuLegacyReevaluationStillOccursOnlyOnTick() {
    let reader = ScriptedCPU()
    let trigger = CPULoadTrigger(thresholdPercent: 50, reader: reader)
    trigger.tick()
    #expect(trigger.isSatisfied())
    trigger.thresholdPercent = 95
    #expect(trigger.isSatisfied()) // Changing a parameter alone does not tick.
    trigger.tick()
    #expect(!trigger.isSatisfied()) // Nil sample still reevaluates old average.
    trigger.thresholdPercent = 20
    trigger.tick()
    #expect(trigger.isSatisfied())
    for _ in 0..<100 { #expect(trigger.isSatisfied()) }
    #expect(reader.reads == 3)
}

@Test func cpuReaderKeepsItsInjectedCountersNilAndTTLContract() {
    var time = Date(timeIntervalSince1970: 0)
    var calls = 0
    var counter: HostCPULoadReader.Ticks? = .init(busy: 10, total: 100)
    let reader = HostCPULoadReader(ttl: 0.5, now: { time }, readTicks: { calls += 1; return counter })
    #expect(reader.currentLoad() == nil)
    #expect(reader.currentLoad() == nil)
    #expect(calls == 1)
    time = time.addingTimeInterval(1)
    counter = nil
    #expect(reader.currentLoad() == nil)
    time = time.addingTimeInterval(1)
    counter = .init(busy: 30, total: 200)
    #expect(reader.currentLoad() == 0.2)
    #expect(calls == 3)
}

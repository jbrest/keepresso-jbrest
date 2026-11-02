import Foundation
import Testing
import SystemObservations
@testable import KeepressoCore

private final class StubPowerSource: PowerSourceMonitoring {
    var current: PowerSourceSnapshot
    init(_ snapshot: PowerSourceSnapshot) { current = snapshot }
}

private final class StubPowerReader: PowerSourceObserving {
    var result: SignalObservation<PowerSourceSnapshot>
    init(_ result: SignalObservation<PowerSourceSnapshot>) { self.result = result }
    func observe(at time: Date) -> SignalObservation<PowerSourceSnapshot> { result }
}

@Test func powerAdapterPreservesTheWholeLegacyPredicateTable() {
    // Explicit upstream predicates from U Trigger.swift:88-94 are the oracle.
    for provider in [PowerSourceSnapshot.Provider.ac, .battery, .unknown] {
        for charging in [false, true] {
            for hasBattery in [false, true] {
                let snapshot = PowerSourceSnapshot(provider: provider, isCharging: charging, hasBattery: hasBattery)
                #expect(PowerSourceTrigger.evaluate(.onACPower, against: snapshot) == (provider == .ac))
                #expect(PowerSourceTrigger.evaluate(.onBattery, against: snapshot) == (provider == .battery))
                #expect(PowerSourceTrigger.evaluate(.charging, against: snapshot) == charging)
            }
        }
    }
}

@Test func powerMonitorFailureKeepsTheOriginalFallbackAndRecovers() {
    let time = Date(timeIntervalSince1970: 123)
    let reader = StubPowerReader(.unavailable(reason: .readFailed, attemptedAt: time))
    let monitor = IOKitPowerSourceMonitor(reader: reader)
    #expect(monitor.current == PowerSourceSnapshot(provider: .unknown, isCharging: false, hasBattery: false))
    let recovered = PowerSourceSnapshot(provider: .ac, isCharging: true, hasBattery: true, percentage: 80)
    reader.result = .available(value: recovered, observedAt: time)
    #expect(monitor.current == recovered)
    reader.result = .unavailable(reason: .readFailed, attemptedAt: time)
    #expect(monitor.current.provider == .unknown)
    #expect(!monitor.current.isCharging)
    #expect(monitor.current.percentage == nil)
}

@Test func powerTriggerReadsCurrentConfigurationAndSnapshotWithoutATick() {
    let monitor = StubPowerSource(.init(provider: .ac, isCharging: false, hasBattery: true))
    let trigger = PowerSourceTrigger(match: .onACPower, monitor: monitor)
    #expect(trigger.isSatisfied())
    trigger.match = .charging
    #expect(!trigger.isSatisfied())
    monitor.current = .init(provider: .unknown, isCharging: true, hasBattery: true)
    #expect(trigger.isSatisfied())
    trigger.match = .onBattery
    #expect(!trigger.isSatisfied())
}

@Test func legacyPowerMatchWireValuesRemainProductOwnedAndUnchanged() throws {
    for (match, json) in [(PowerSourceTrigger.Match.onACPower, "\"onACPower\""), (.onBattery, "\"onBattery\""), (.charging, "\"charging\"")] {
        let encoded = try JSONEncoder().encode(match)
        #expect(String(data: encoded, encoding: .utf8) == json)
        let decoded = try JSONDecoder().decode(PowerSourceTrigger.Match.self, from: Data(json.utf8))
        #expect(decoded == match)
    }
}

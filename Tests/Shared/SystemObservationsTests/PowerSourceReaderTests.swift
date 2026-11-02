import Foundation
import Testing
import RuleModel
@testable import SystemObservations

@Test func powerReaderReportsAcquisitionFailureWithoutInventingAValue() {
    let time = Date(timeIntervalSince1970: 123)
    let reader = IOKitPowerSourceReader(read: { nil })
    #expect(reader.observe(at: time) == .unavailable(reason: .readFailed, attemptedAt: time))
}

@Test func powerReaderPreservesPartialSnapshotsAndCallerTime() {
    let time = Date(timeIntervalSince1970: 456)
    let partial = PowerSourceSnapshot(provider: .unknown, isCharging: true, hasBattery: true, percentage: 75)
    let reader = IOKitPowerSourceReader(read: { partial })
    #expect(reader.observe(at: time) == .available(value: partial, observedAt: time))
}

@Test func realPowerReaderReadOnlySmoke() {
    let time = Date()
    let observation = IOKitPowerSourceReader().observe(at: time)
    switch observation {
    case .available(let snapshot, let observedAt):
        #expect(observedAt == time)
        print("Power reader smoke: available provider=\(snapshot.provider.rawValue) charging=\(snapshot.isCharging) battery=\(snapshot.hasBattery)")
    case .unavailable(let reason, let attemptedAt):
        #expect(attemptedAt == time)
        print("Power reader smoke: unavailable reason=\(reason)")
    }
}

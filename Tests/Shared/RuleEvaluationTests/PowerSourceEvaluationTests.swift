import Foundation
import Testing
import RuleModel
import RuleEvaluation

@Test func powerConditionsDistinguishKnownSourcesAndCharging() {
    let time = Date(timeIntervalSince1970: 100)
    let ac = PowerSourceSnapshot(provider: .ac, isCharging: false, hasBattery: false)
    let battery = PowerSourceSnapshot(provider: .battery, isCharging: false, hasBattery: true)
    let charging = PowerSourceSnapshot(provider: .ac, isCharging: true, hasBattery: true)
    #expect(PowerSourceEvaluation.evaluate(.onACPower, observation: .available(value: ac, observedAt: time)) == .satisfied)
    #expect(PowerSourceEvaluation.evaluate(.onBattery, observation: .available(value: ac, observedAt: time)) == .unsatisfied)
    #expect(PowerSourceEvaluation.evaluate(.charging, observation: .available(value: ac, observedAt: time)) == .unsatisfied)
    #expect(PowerSourceEvaluation.evaluate(.onBattery, observation: .available(value: battery, observedAt: time)) == .satisfied)
    #expect(PowerSourceEvaluation.evaluate(.onACPower, observation: .available(value: battery, observedAt: time)) == .unsatisfied)
    #expect(PowerSourceEvaluation.evaluate(.charging, observation: .available(value: charging, observedAt: time)) == .satisfied)
}

@Test func powerReadFailureIsUnknownForEveryCondition() {
    let missing = SignalObservation<PowerSourceSnapshot>.unavailable(
        reason: .readFailed, attemptedAt: Date(timeIntervalSince1970: 100)
    )
    for condition in PowerSourceCondition.allCases {
        #expect(PowerSourceEvaluation.evaluate(condition, observation: missing) == .unknown)
    }
}

@Test func unknownPowerProviderDoesNotDiscardIndependentChargingInformation() {
    let time = Date(timeIntervalSince1970: 100)
    for charging in [false, true] {
        let snapshot = PowerSourceSnapshot(provider: .unknown, isCharging: charging, hasBattery: true)
        let observation = SignalObservation.available(value: snapshot, observedAt: time)
        #expect(PowerSourceEvaluation.evaluate(.onACPower, observation: observation) == .unknown)
        #expect(PowerSourceEvaluation.evaluate(.onBattery, observation: observation) == .unknown)
        #expect(PowerSourceEvaluation.evaluate(.charging, observation: observation) == (charging ? .satisfied : .unsatisfied))
    }
}

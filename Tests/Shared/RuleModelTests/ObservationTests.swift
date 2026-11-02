import Foundation
import Testing
import RuleModel

@Test func availableNegativeObservationIsNotAReadFailure() {
    let time = Date(timeIntervalSince1970: 123)
    let negative = SignalObservation<Bool>.available(value: false, observedAt: time)
    let unavailable = SignalObservation<Bool>.unavailable(reason: .readFailed, attemptedAt: time)
    #expect(negative != unavailable)
    guard case .available(let value, let observedAt) = negative else {
        Issue.record("Available false must remain an available observation")
        return
    }
    #expect(value == false)
    #expect(observedAt == time)
}

@Test func unavailableObservationRetainsItsReasonAndAttemptTime() {
    let time = Date(timeIntervalSince1970: 456)
    let observation = SignalObservation<Double>.unavailable(reason: .insufficientData, attemptedAt: time)
    guard case .unavailable(let reason, let attemptedAt) = observation else {
        Issue.record("Unavailable acquisition must not invent a sample")
        return
    }
    #expect(reason == .insufficientData)
    #expect(attemptedAt == time)
}

@Test func observedZeroIsDifferentFromTheFirstMissingRateSample() {
    let time = Date(timeIntervalSince1970: 789)
    let zero = SignalObservation<Double>.available(value: 0, observedAt: time)
    let initial = SignalObservation<Double>.unavailable(reason: .notYetSampled, attemptedAt: time)
    #expect(zero != initial)
}

@Test func sharedObservationCanCrossAnIsolationBoundary() async {
    let sample = SignalObservation<Int>.available(value: 42, observedAt: Date(timeIntervalSince1970: 0))
    let received = await Task.detached { sample }.value
    #expect(received == sample)
}

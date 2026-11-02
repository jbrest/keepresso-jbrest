import Foundation
import Testing
import RuleModel
import RuleEvaluation

@Test func sharedCPUUnknownDoesNotSilentlyApplyTheLegacyFallback() {
    let state = CPUThresholdEvaluation.step(.init(), sample: 0.8, thresholdPercent: 50)
    let unavailable = SignalObservation<Double>.unavailable(reason: .readFailed, attemptedAt: Date(timeIntervalSince1970: 0))
    let result = CPUThresholdEvaluation.evaluate(unavailable, state: state, thresholdPercent: 95)
    #expect(result.verdict == .unknown)
    #expect(result.state == state)
    #expect(!CPUThresholdEvaluation.reevaluate(state, thresholdPercent: 95).isSatisfied)
}

@Test func sharedCPUThresholdKeepsClampingHysteresisAndLowThresholdRelease() {
    var state = CPUThresholdEvaluation.step(.init(), sample: 1.5, thresholdPercent: 5)
    #expect(state.average == 1)
    for _ in 0..<40 { state = CPUThresholdEvaluation.step(state, sample: -0.1, thresholdPercent: 5) }
    #expect(!state.isSatisfied)
    #expect(CPUThresholdEvaluation.reevaluate(state, thresholdPercent: 0).average == nil)
}

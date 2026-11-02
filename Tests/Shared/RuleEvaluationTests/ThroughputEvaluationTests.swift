import Foundation
import Testing
import RuleModel
import RuleEvaluation

@Test func throughputUnknownDoesNotConsumeAnAverage() {
    let active = ThroughputThresholdEvaluation.step(.init(), sampleBytesPerSecond: 2048,
                                                    thresholdKilobytesPerSecond: 1)
    #expect(active.isSatisfied)
    let result = ThroughputThresholdEvaluation.evaluate(
        .unavailable(reason: .readFailed, attemptedAt: Date()), state: active,
        thresholdKilobytesPerSecond: 3)
    #expect(result.verdict == .unknown)
    #expect(result.state == active)
    #expect(!ThroughputThresholdEvaluation.reevaluate(active, thresholdKilobytesPerSecond: 3).isSatisfied)
    #expect(ThroughputThresholdEvaluation.step(.init(), sampleBytesPerSecond: -10,
                                              thresholdKilobytesPerSecond: 1).average == 0)
}

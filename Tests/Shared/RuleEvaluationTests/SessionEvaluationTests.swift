import Foundation
import Testing
import RuleModel
import RuleEvaluation

@Test func sessionEvaluationPreservesUnknownAndRejectsInvalidCounts() {
    let at = Date(timeIntervalSince1970: 1)
    #expect(SessionEvaluation.ssh(.unavailable(reason: .unsupported, attemptedAt: at)) == .unknown)
    #expect(SessionEvaluation.ssh(.available(value: .init(authenticatedSessionCount: -1), observedAt: at)) == .unknown)
    #expect(SessionEvaluation.ssh(.available(value: .init(authenticatedSessionCount: 0), observedAt: at)) == .unsatisfied)
    #expect(SessionEvaluation.ssh(.available(value: .init(authenticatedSessionCount: 2), observedAt: at)) == .satisfied)
}

@Test func consoleSessionEvaluationUsesLoginEvidenceNotConnectionState() {
    let at = Date(timeIntervalSince1970: 1)
    #expect(SessionEvaluation.console(.unavailable(reason: .readFailed, attemptedAt: at)) == .unknown)
    #expect(SessionEvaluation.console(.available(value: .init(userNames: []), observedAt: at)) == .unsatisfied)
    #expect(SessionEvaluation.console(.available(value: .init(userNames: ["alice"]), observedAt: at)) == .satisfied)
}

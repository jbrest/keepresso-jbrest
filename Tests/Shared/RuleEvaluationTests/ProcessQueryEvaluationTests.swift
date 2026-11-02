import Foundation
import Testing
import RuleModel
import RuleEvaluation

@Test func processQuerySeparatesEmptyFromUnavailable() {
    let failure = SignalObservation<[String]>.unavailable(reason: .readFailed, attemptedAt: Date())
    #expect(ProcessQueryEvaluation.evaluate(failure, query: "node") == .unknown)
    #expect(ProcessQueryEvaluation.evaluate(failure, query: "  ") == .unsatisfied)
    #expect(ProcessQueryEvaluation.evaluate(.available(value: [], observedAt: Date()), query: "node") == .unsatisfied)
    #expect(ProcessQueryEvaluation.evaluate(.available(value: ["NODE task"], observedAt: Date()), query: "node") == .satisfied)
}

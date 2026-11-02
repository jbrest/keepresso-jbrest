import Testing
import RuleEvaluation

private struct CombinationCase: Sendable {
    let left: Verdict
    let right: Verdict
    let any: Verdict
    let all: Verdict
}

private let truthTable: [CombinationCase] = [
    .init(left: .satisfied, right: .satisfied, any: .satisfied, all: .satisfied),
    .init(left: .satisfied, right: .unsatisfied, any: .satisfied, all: .unsatisfied),
    .init(left: .satisfied, right: .unknown, any: .satisfied, all: .unknown),
    .init(left: .unsatisfied, right: .satisfied, any: .satisfied, all: .unsatisfied),
    .init(left: .unsatisfied, right: .unsatisfied, any: .unsatisfied, all: .unsatisfied),
    .init(left: .unsatisfied, right: .unknown, any: .unknown, all: .unsatisfied),
    .init(left: .unknown, right: .satisfied, any: .satisfied, all: .unknown),
    .init(left: .unknown, right: .unsatisfied, any: .unknown, all: .unsatisfied),
    .init(left: .unknown, right: .unknown, any: .unknown, all: .unknown),
]

@Test func combinationsFollowTheCompleteThreeStateTruthTable() {
    for entry in truthTable {
        #expect(Verdict.any([entry.left, entry.right]) == entry.any)
        #expect(Verdict.all([entry.left, entry.right]) == entry.all)
    }
}

@Test func emptyRuleSetsNeverRequestAHold() {
    #expect(Verdict.any([]) == .unsatisfied)
    #expect(Verdict.all([]) == .unsatisfied)
}

@Test func aSingleUnknownRemainsUnknown() {
    #expect(Verdict.any([.unknown]) == .unknown)
    #expect(Verdict.all([.unknown]) == .unknown)
}

@Test func knownResultsDominateUnknownRegardlessOfPosition() {
    #expect(Verdict.any([.unknown, .unsatisfied, .satisfied]) == .satisfied)
    #expect(Verdict.any([.satisfied, .unknown, .unsatisfied]) == .satisfied)
    #expect(Verdict.all([.unknown, .satisfied, .unsatisfied]) == .unsatisfied)
    #expect(Verdict.all([.unsatisfied, .unknown, .satisfied]) == .unsatisfied)
}

@Test func unknownIsPreservedWhenNoKnownResultDecidesTheCombination() {
    #expect(Verdict.any([.unsatisfied, .unknown, .unsatisfied]) == .unknown)
    #expect(Verdict.all([.satisfied, .unknown, .satisfied]) == .unknown)
}

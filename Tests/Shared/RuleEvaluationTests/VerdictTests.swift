import Testing
import RuleEvaluation

private struct CombinationCase: Sendable {
    let left: RuleVerdict
    let right: RuleVerdict
    let any: RuleVerdict
    let all: RuleVerdict
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
        #expect(RuleVerdict.any([entry.left, entry.right]) == entry.any)
        #expect(RuleVerdict.all([entry.left, entry.right]) == entry.all)
    }
}

@Test func emptyRuleSetsNeverRequestAHold() {
    #expect(RuleVerdict.any([]) == .unsatisfied)
    #expect(RuleVerdict.all([]) == .unsatisfied)
}

@Test func aSingleUnknownRemainsUnknown() {
    #expect(RuleVerdict.any([.unknown]) == .unknown)
    #expect(RuleVerdict.all([.unknown]) == .unknown)
}

@Test func knownResultsDominateUnknownRegardlessOfPosition() {
    #expect(RuleVerdict.any([.unknown, .unsatisfied, .satisfied]) == .satisfied)
    #expect(RuleVerdict.any([.satisfied, .unknown, .unsatisfied]) == .satisfied)
    #expect(RuleVerdict.all([.unknown, .satisfied, .unsatisfied]) == .unsatisfied)
    #expect(RuleVerdict.all([.unsatisfied, .unknown, .satisfied]) == .unsatisfied)
}

@Test func unknownIsPreservedWhenNoKnownResultDecidesTheCombination() {
    #expect(RuleVerdict.any([.unsatisfied, .unknown, .unsatisfied]) == .unknown)
    #expect(RuleVerdict.all([.satisfied, .unknown, .satisfied]) == .unknown)
}

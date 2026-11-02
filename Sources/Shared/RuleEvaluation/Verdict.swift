import RuleModel

/// A condition result. Products decide how unknown affects their own demand;
/// combining results never silently turns missing information into false.
public enum Verdict: CaseIterable, Equatable, Sendable {
    case satisfied
    case unsatisfied
    case unknown

    /// Kleene OR. Empty input is unsatisfied, matching Keepresso's empty rules.
    public static func any<Results: Sequence>(_ results: Results) -> Verdict
    where Results.Element == Verdict {
        var combined = Verdict.unsatisfied
        for result in results {
            switch result {
            case .satisfied: return .satisfied
            case .unknown: combined = .unknown
            case .unsatisfied: break
            }
        }
        return combined
    }

    /// Kleene AND, with an explicit empty-input exception for keep-awake rules:
    /// enabling a rule set with no conditions must not itself request a hold.
    public static func all<Results: Sequence>(_ results: Results) -> Verdict
    where Results.Element == Verdict {
        var hasResult = false
        var combined = Verdict.satisfied
        for result in results {
            hasResult = true
            switch result {
            case .unsatisfied: return .unsatisfied
            case .unknown: combined = .unknown
            case .satisfied: break
            }
        }
        return hasResult ? combined : .unsatisfied
    }
}

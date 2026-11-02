import RuleModel

public enum SessionEvaluation {
    public static func ssh(_ observation: SignalObservation<SSHSessionSnapshot>) -> RuleVerdict {
        guard case .available(let snapshot, _) = observation else { return .unknown }
        guard snapshot.authenticatedSessionCount >= 0 else { return .unknown }
        return snapshot.authenticatedSessionCount > 0 ? .satisfied : .unsatisfied
    }

    public static func console(_ observation: SignalObservation<ConsoleSessionSnapshot>) -> RuleVerdict {
        guard case .available(let snapshot, _) = observation else { return .unknown }
        return snapshot.userNames.isEmpty ? .unsatisfied : .satisfied
    }
}

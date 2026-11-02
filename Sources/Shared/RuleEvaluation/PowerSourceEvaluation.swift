// Adapted from KeepressoCore/Trigger.swift:88-94, upstream 7ea73a6.
import RuleModel

public enum PowerSourceEvaluation {
    public static func evaluate(
        _ condition: PowerSourceCondition,
        observation: SignalObservation<PowerSourceSnapshot>
    ) -> RuleVerdict {
        guard case .available(let snapshot, _) = observation else { return .unknown }
        return evaluate(condition, snapshot: snapshot)
    }

    /// A snapshot-only entry point for legacy callers without observation times.
    public static func evaluate(
        _ condition: PowerSourceCondition,
        snapshot: PowerSourceSnapshot
    ) -> RuleVerdict {
        switch condition {
        case .charging:
            return snapshot.isCharging ? .satisfied : .unsatisfied
        case .onACPower:
            guard snapshot.provider != .unknown else { return .unknown }
            return snapshot.provider == .ac ? .satisfied : .unsatisfied
        case .onBattery:
            guard snapshot.provider != .unknown else { return .unknown }
            return snapshot.provider == .battery ? .satisfied : .unsatisfied
        }
    }
}

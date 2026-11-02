// Adapted from KeepressoCore/CPULoad.swift:93-153, upstream 7ea73a6.
import RuleModel

public struct CPUThresholdState: Equatable, Sendable {
    public var average: Double?
    public var isSatisfied = false
    public init() {}
}

public enum CPUThresholdEvaluation {
    public static let alpha = 0.25
    public static let hysteresis = 0.05

    public static func step(_ state: CPUThresholdState, sample: Double, thresholdPercent: Int) -> CPUThresholdState {
        update(state, sample: sample, thresholdPercent: thresholdPercent)
    }

    /// Reevaluate an existing average without accumulating another sample.
    public static func reevaluate(_ state: CPUThresholdState, thresholdPercent: Int) -> CPUThresholdState {
        update(state, sample: nil, thresholdPercent: thresholdPercent)
    }

    /// Availability remains explicit. A product can separately request retained
    /// average evaluation, rather than silently coercing this unknown verdict.
    public static func evaluate(
        _ observation: SignalObservation<Double>, state: CPUThresholdState, thresholdPercent: Int
    ) -> (state: CPUThresholdState, verdict: RuleVerdict) {
        guard case .available(let sample, _) = observation else { return (state, .unknown) }
        let next = step(state, sample: sample, thresholdPercent: thresholdPercent)
        return (next, next.isSatisfied ? .satisfied : .unsatisfied)
    }

    private static func update(_ state: CPUThresholdState, sample: Double?, thresholdPercent: Int) -> CPUThresholdState {
        var next = state
        // A non-positive threshold is malformed (the picker never makes one).
        // Treat it as "never satisfied" instead of the always-true it would
        // otherwise compute (average >= 0), so a corrupt or imported rule can't
        // pin the Mac awake with nothing able to release it.
        guard thresholdPercent > 0 else {
            next.average = nil
            next.isSatisfied = false
            return next
        }
        if let sample {
            let clamped = min(max(sample, 0), 1)
            next.average = state.average.map { $0 + alpha * (clamped - $0) } ?? clamped
        }
        guard let average = next.average else {
            next.isSatisfied = false
            return next
        }
        let on = Double(thresholdPercent) / 100
        // Keep the release band strictly below `on` but always positive: a flat
        // `on - hysteresis` goes <= 0 for thresholds <= 5%, which (with the
        // average clamped to 0...1) would make the release test always true and
        // latch the trigger on forever.
        let off = max(on - hysteresis, on * 0.5)
        next.isSatisfied = state.isSatisfied ? average >= off : average >= on
        return next
    }
}

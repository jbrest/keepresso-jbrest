// Adapted from KeepressoCore/NetworkThroughput.swift:118-174, upstream 7ea73a6.
import RuleModel

public struct ThroughputThresholdState: Equatable, Sendable {
    public var average: Double?
    public var isSatisfied = false
    public init() {}
}

public enum ThroughputThresholdEvaluation {
    public static let alpha = 0.25
    public static let releaseFraction = 0.7

    public static func step(_ state: ThroughputThresholdState, sampleBytesPerSecond: Double,
                            thresholdKilobytesPerSecond: Int) -> ThroughputThresholdState {
        update(state, sample: sampleBytesPerSecond, thresholdKilobytesPerSecond: thresholdKilobytesPerSecond)
    }

    public static func reevaluate(_ state: ThroughputThresholdState,
                                  thresholdKilobytesPerSecond: Int) -> ThroughputThresholdState {
        update(state, sample: nil, thresholdKilobytesPerSecond: thresholdKilobytesPerSecond)
    }

    public static func evaluate(_ observation: SignalObservation<Double>, state: ThroughputThresholdState,
                                thresholdKilobytesPerSecond: Int) -> (state: ThroughputThresholdState, verdict: RuleVerdict) {
        guard case .available(let sample, _) = observation else { return (state, .unknown) }
        let next = step(state, sampleBytesPerSecond: sample, thresholdKilobytesPerSecond: thresholdKilobytesPerSecond)
        return (next, next.isSatisfied ? .satisfied : .unsatisfied)
    }

    private static func update(_ state: ThroughputThresholdState, sample: Double?,
                               thresholdKilobytesPerSecond: Int) -> ThroughputThresholdState {
        var next = state
        // A non-positive threshold is malformed (the picker never makes one).
        // Treat it as "never satisfied" instead of the always-true it would
        // otherwise compute (average >= 0), so a corrupt or imported rule can't
        // pin the Mac awake with nothing able to release it.
        guard thresholdKilobytesPerSecond > 0 else {
            next.average = nil
            next.isSatisfied = false
            return next
        }
        if let sample {
            let clamped = max(sample, 0)
            next.average = state.average.map { $0 + alpha * (clamped - $0) } ?? clamped
        }
        guard let average = next.average else {
            next.isSatisfied = false
            return next
        }
        let on = Double(thresholdKilobytesPerSecond) * 1024
        let off = on * releaseFraction
        next.isSatisfied = state.isSatisfied ? average >= off : average >= on
        return next
    }
}

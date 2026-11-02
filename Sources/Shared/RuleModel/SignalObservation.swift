import Foundation

/// Why acquisition could not supply a usable observation. Products map these
/// values into their own saved/wire formats and user-facing explanations.
public enum ObservationUnavailableReason: Equatable, Sendable {
    case notYetSampled
    case insufficientData
    case permissionDenied
    case unsupported
    case readFailed
    case invalidData
}

/// An acquisition result, not a condition verdict. An available false or zero
/// remains different from a failed read. Hosts provide time explicitly.
public enum SignalObservation<Value: Sendable>: Sendable {
    case available(value: Value, observedAt: Date)
    case unavailable(reason: ObservationUnavailableReason, attemptedAt: Date)
}

extension SignalObservation: Equatable where Value: Equatable {}

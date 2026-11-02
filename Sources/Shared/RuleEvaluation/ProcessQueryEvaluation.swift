// Adapted from KeepressoCore/Trigger.swift:225-229, upstream 7ea73a6.
import Foundation
import RuleModel

public enum ProcessQueryEvaluation {
    public static func evaluate(_ observation: SignalObservation<[String]>, query: String) -> RuleVerdict {
        // Preserve the original empty-query rule independently of availability.
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return .unsatisfied }
        guard case .available(let processes, _) = observation else { return .unknown }
        return matches(query, in: processes) ? .satisfied : .unsatisfied
    }

    public static func matches(_ query: String, in processes: [String]) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return false }
        return processes.contains { $0.lowercased().contains(needle) }
    }
}

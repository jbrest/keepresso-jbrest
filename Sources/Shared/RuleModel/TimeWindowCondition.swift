// Adapted from KeepressoCore/TimeWindow.swift, upstream 7ea73a6.
import Foundation

public struct TimeWindowCondition: Equatable, Hashable, Sendable {
    /// Window start, in minutes from midnight (0..<1440).
    public var startMinutes: Int
    /// Window end, in minutes from midnight (0..<1440). An end at or before
    /// the start wraps past midnight into the next day (22:00-6:00).
    public var endMinutes: Int
    /// The weekdays the window *starts* on, in `Calendar`'s numbering
    /// (1 = Sunday … 7 = Saturday). Empty means every day.
    public var weekdays: Set<Int>

    public init(startMinutes: Int, endMinutes: Int, weekdays: Set<Int> = []) {
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.weekdays = weekdays
    }

}

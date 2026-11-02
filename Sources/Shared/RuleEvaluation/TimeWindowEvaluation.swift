// Adapted from KeepressoCore/TimeWindow.swift:77-97, upstream 7ea73a6.
import Foundation
import RuleModel

public enum TimeWindowEvaluation {
    public static func evaluate(
        _ condition: TimeWindowCondition, at date: Date, calendar: Calendar
    ) -> RuleVerdict {
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        guard let weekday = components.weekday,
              let hour = components.hour,
              let minute = components.minute else { return .unknown }
        let minutes = hour * 60 + minute
        func starts(on day: Int) -> Bool {
            condition.weekdays.isEmpty || condition.weekdays.contains(day)
        }
        let matches: Bool
        if condition.startMinutes < condition.endMinutes {
            matches = starts(on: weekday) && minutes >= condition.startMinutes && minutes < condition.endMinutes
        } else if minutes >= condition.startMinutes {
            matches = starts(on: weekday)
        } else if minutes < condition.endMinutes {
            let yesterday = weekday == 1 ? 7 : weekday - 1
            matches = starts(on: yesterday)
        } else {
            matches = false
        }
        return matches ? .satisfied : .unsatisfied
    }
}

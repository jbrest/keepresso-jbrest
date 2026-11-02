import Foundation
import Testing
import RuleModel
import RuleEvaluation

@Test func sharedWindowUsesInclusiveStartExclusiveEndAndStartDayOwnership() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let friday = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 22))!
    let window = TimeWindowCondition(startMinutes: 1320, endMinutes: 360, weekdays: [6])
    #expect(TimeWindowEvaluation.evaluate(window, at: friday.addingTimeInterval(-60), calendar: calendar) == .unsatisfied)
    #expect(TimeWindowEvaluation.evaluate(window, at: friday, calendar: calendar) == .satisfied)
    #expect(TimeWindowEvaluation.evaluate(window, at: friday.addingTimeInterval(7 * 3600), calendar: calendar) == .satisfied)
    #expect(TimeWindowEvaluation.evaluate(window, at: friday.addingTimeInterval(8 * 3600), calendar: calendar) == .unsatisfied)
}

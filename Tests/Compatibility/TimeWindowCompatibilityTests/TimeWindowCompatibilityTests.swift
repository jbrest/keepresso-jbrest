import Foundation
import Testing
@testable import KeepressoCore

private func legacyWindow(_ rule: TimeWindowRule, at date: Date, calendar: Calendar) -> Bool {
    // Verbatim decision body from U TimeWindow.swift:77-97, used as the oracle.
    let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
    guard let weekday = components.weekday, let hour = components.hour,
          let minute = components.minute else { return false }
    let minutes = hour * 60 + minute
    func starts(on day: Int) -> Bool { rule.weekdays.isEmpty || rule.weekdays.contains(day) }
    if rule.startMinutes < rule.endMinutes {
        return starts(on: weekday) && minutes >= rule.startMinutes && minutes < rule.endMinutes
    }
    if minutes >= rule.startMinutes { return starts(on: weekday) }
    if minutes < rule.endMinutes { return starts(on: weekday == 1 ? 7 : weekday - 1) }
    return false
}

@Test func windowAdapterMatchesUpstreamAcrossBoundariesAndMalformedValues() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let sunday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
    for (start, end) in [(0, 0), (540, 1080), (1320, 360), (360, 360), (-1, 1500), (1500, -1)] {
        for days in [Set<Int>(), [1], [6], [2, 3, 4, 5, 6], [0, 8]] {
            let rule = TimeWindowRule(startMinutes: start, endMinutes: end, weekdays: days)
            for day in 0..<7 {
                for minute in [0, 359, 360, 539, 540, 1079, 1080, 1319, 1320, 1439] {
                    let date = sunday.addingTimeInterval(Double(day * 86400 + minute * 60))
                    #expect(TimeWindowTrigger.evaluate(rule, at: date, calendar: calendar) == legacyWindow(rule, at: date, calendar: calendar))
                }
            }
        }
    }
}

@Test func windowAdapterPreservesDSTAndNonGregorianCalendarBehavior() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
    let parser = ISO8601DateFormatter()
    let rule = TimeWindowRule(startMinutes: 90, endMinutes: 180)
    for timestamp in ["2026-03-08T06:59:00Z", "2026-03-08T07:00:00Z", "2026-11-01T05:30:00Z", "2026-11-01T06:30:00Z"] {
        let date = try #require(parser.date(from: timestamp))
        #expect(TimeWindowTrigger.evaluate(rule, at: date, calendar: calendar) == legacyWindow(rule, at: date, calendar: calendar))
    }
    var hebrew = Calendar(identifier: .hebrew)
    hebrew.timeZone = calendar.timeZone
    let date = try #require(parser.date(from: "2026-11-01T06:30:00Z"))
    #expect(TimeWindowTrigger.evaluate(rule, at: date, calendar: hebrew) == legacyWindow(rule, at: date, calendar: hebrew))
}

@Test func windowRuleKeepsItsLegacyJSONAndImmediateEditing() throws {
    let json = Data(#"{"startMinutes":540,"endMinutes":1080,"weekdays":[2,3,4,5,6]}"#.utf8)
    let rule = try JSONDecoder().decode(TimeWindowRule.self, from: json)
    let roundtrip = try JSONDecoder().decode(TimeWindowRule.self, from: JSONEncoder().encode(rule))
    #expect(roundtrip == rule)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let time = calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 10))!
    let trigger = TimeWindowTrigger(rule: rule, now: { time }, calendar: calendar)
    #expect(trigger.isSatisfied())
    trigger.rule.endMinutes = 600
    #expect(!trigger.isSatisfied())
}

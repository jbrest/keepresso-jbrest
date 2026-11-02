import Foundation
import Testing
import RuleModel
import SystemObservations

@Test func consoleAccountingFiltersTerminalSystemSetupAndDeadRecords() {
    let at = Date(timeIntervalSince1970: 1)
    let rows: [ConsoleLoginRecord] = [
        .init(userName: "alice", line: "console", isUserProcess: true),
        .init(userName: "alice", line: "console", isUserProcess: true),
        .init(userName: "bob", line: "ttys000", isUserProcess: true),
        .init(userName: "carol", line: "console", isUserProcess: false),
        .init(userName: "loginwindow", line: "console", isUserProcess: true),
        .init(userName: "_mbsetupuser", line: "console", isUserProcess: true)
    ]
    let reader = ConsoleSessionReader(now: { at }, read: { rows }, isInteractiveAccount: { $0 == "alice" || $0 == "bob" })
    #expect(reader.observe() == .available(value: .init(userNames: ["alice"]), observedAt: at))
}

@Test func consoleAccountingPrototypeIncludesMultipleLoginRecords() {
    let at = Date(timeIntervalSince1970: 1)
    let reader = ConsoleSessionReader(now: { at }, read: { [
        .init(userName: "alice", line: "console", isUserProcess: true),
        .init(userName: "bob", line: "console", isUserProcess: true)
    ] }, isInteractiveAccount: { _ in true })
    #expect(reader.observe() == .available(value: .init(userNames: ["alice", "bob"]), observedAt: at))
}

@Test func consoleFailuresAndUnresolvedAccountsAreNotEmptySessions() {
    let at = Date(timeIntervalSince1970: 1)
    #expect(ConsoleSessionReader(now: { at }, read: { nil }).observe() == .unavailable(reason: .readFailed, attemptedAt: at))
    let empty = ConsoleSessionReader(now: { at }, read: { [] })
    #expect(empty.observe() == .available(value: .init(userNames: []), observedAt: at))
    let malformed = ConsoleSessionReader(now: { at }, read: { [.init(userName: "", line: "console", isUserProcess: true)] })
    #expect(malformed.observe() == .unavailable(reason: .invalidData, attemptedAt: at))
    let unresolved = ConsoleSessionReader(now: { at }, read: { [.init(userName: "missing", line: "console", isUserProcess: true)] },
                                          isInteractiveAccount: { _ in nil })
    #expect(unresolved.observe() == .unavailable(reason: .readFailed, attemptedAt: at))
}

@Test func knownSystemAndSetupAccountsAreExcludedWithoutLookup() {
    for name in ["root", "loginwindow", "_windowserver", "_mbsetupuser", "mbsetupuser", ""] {
        #expect(ConsoleSessionReader.isInteractiveAccount(name) == false)
    }
}

@Test func realConsoleAccountingReadOnlySmoke() {
    switch ConsoleSessionReader().observe() {
    case .available(let snapshot, _): print("Console accounting prototype smoke: available userCount=\(snapshot.userNames.count)")
    case .unavailable(let reason, _): Issue.record("Console accounting unavailable: \(reason)")
    }
}

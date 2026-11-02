import Foundation
import Darwin
import RuleModel

public protocol ConsoleSessionObserving: AnyObject {
    func observe() -> SignalObservation<ConsoleSessionSnapshot>
}

public struct ConsoleLoginRecord: Equatable, Sendable {
    public var userName: String
    public var line: String
    public var isUserProcess: Bool
    public init(userName: String, line: String, isUserProcess: Bool) {
        self.userName = userName
        self.line = line
        self.isUserProcess = isUserProcess
    }
}

/// Read-only utmpx prototype, not wired to a product. It observes logged-in
/// console accounting rather than the current screen owner or VNC connection.
/// Fast user switching and separate virtual sessions still require O5 testing.
/// Accounting and account lookup are synchronous; drive this from a worker.
public final class ConsoleSessionReader: ConsoleSessionObserving {
    // utmpx iteration has process-global state. This serializes our readers;
    // other code using getutxent in the same process must share this discipline.
    private static let accountingLock = NSLock()
    private let now: () -> Date
    private let read: () -> [ConsoleLoginRecord]?
    private let isInteractiveAccount: (String) -> Bool?

    public init(now: @escaping () -> Date = Date.init,
                read: @escaping () -> [ConsoleLoginRecord]? = ConsoleSessionReader.readAccounting,
                isInteractiveAccount: @escaping (String) -> Bool? = ConsoleSessionReader.isInteractiveAccount) {
        self.now = now
        self.read = read
        self.isInteractiveAccount = isInteractiveAccount
    }

    public func observe() -> SignalObservation<ConsoleSessionSnapshot> {
        guard let records = read() else { return .unavailable(reason: .readFailed, attemptedAt: now()) }
        var users = Set<String>()
        for record in records where record.isUserProcess && record.line == "console" {
            // Malformed accounting must not silently become "nobody logged in".
            guard !record.userName.isEmpty else { return .unavailable(reason: .invalidData, attemptedAt: now()) }
            guard let interactive = isInteractiveAccount(record.userName) else {
                return .unavailable(reason: .readFailed, attemptedAt: now())
            }
            if interactive { users.insert(record.userName) }
        }
        return .available(value: .init(userNames: users), observedAt: now())
    }

    public static func isInteractiveAccount(_ name: String) -> Bool? {
        guard !name.isEmpty, !name.hasPrefix("_"),
              !["root", "loginwindow", "mbsetupuser"].contains(name) else { return false }
        // Reentrant lookup avoids getpwnam's global returned buffer. Missing or
        // unresolved account data is handled conservatively by the prototype.
        var entry = passwd()
        var result: UnsafeMutablePointer<passwd>?
        var buffer = [CChar](repeating: 0, count: 16_384)
        let status = getpwnam_r(name, &entry, &buffer, buffer.count, &result)
        guard status == 0, result != nil else { return nil }
        return entry.pw_uid >= 501
    }

    public static func readAccounting() -> [ConsoleLoginRecord]? {
        accountingLock.lock()
        defer { accountingLock.unlock() }
        setutxent()
        defer { endutxent() }
        var records: [ConsoleLoginRecord] = []
        while true {
            errno = 0
            guard let pointer = getutxent() else { return errno == 0 ? records : nil }
            var entry = pointer.pointee
            guard records.count < 4096 else { return nil }
            guard let user = decode(&entry.ut_user), let line = decode(&entry.ut_line) else { return nil }
            records.append(.init(userName: user, line: line, isUserProcess: entry.ut_type == USER_PROCESS))
        }
    }

    private static func decode<T>(_ field: inout T) -> String? {
        withUnsafeBytes(of: &field) { bytes in
            guard let end = bytes.firstIndex(of: 0) else { return nil }
            return String(bytes: bytes[..<end], encoding: .utf8)
        }
    }
}

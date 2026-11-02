import Foundation
import RuleModel

public protocol SSHSessionObserving: AnyObject {
    func observe() -> SignalObservation<SSHSessionSnapshot>
}

/// Evidence must identify the real executable independently of its mutable
/// command line. These values are fixtures until an OS backend is validated.
public struct OpenSSHProcessEvidence: Equatable, Sendable {
    public enum Executable: Sendable {
        case sshd, session, authentication, other
    }
    public var pid: Int32
    public var parentPID: Int32
    public var executable: Executable
    public var title: String
    public init(pid: Int32, parentPID: Int32 = 0, executable: Executable, title: String) {
        self.pid = pid
        self.parentPID = parentPID
        self.executable = executable
        self.title = title
    }
}

/// Source-informed prototype, not a production process-name heuristic.
/// See evidence/A7.md for source references and the missing live validation.
public enum OpenSSHSessionClassifier {
    public static func classify(_ processes: [OpenSSHProcessEvidence]) -> SSHSessionSnapshot? {
        guard processes.count <= 4096 else { return nil }
        var authenticated = Set<Int32>()
        var seen = Set<Int32>()
        for process in processes {
            guard process.pid > 0, seen.insert(process.pid).inserted else { return nil }
            let prefix: String
            switch process.executable {
            case .other, .authentication: continue
            case .sshd:
                // A verified server executable with its ordinary invocation
                // title is not proof of authentication (including inetd mode).
                if process.title == "/usr/sbin/sshd" || process.title.hasPrefix("/usr/sbin/sshd ") { continue }
                prefix = "sshd: "
            case .session: prefix = "sshd-session: "
            }
            guard process.title.hasPrefix(prefix) else { return nil }
            let payload = String(process.title.dropFirst(prefix.count))
            // Monitor and pre-auth children are never proof of authentication.
            if ["[accepted]", "[rexeced]", "[net]"].contains(payload)
                || payload.contains("[listener]") || payload.hasSuffix(" [priv]") || payload.hasSuffix(" [preauth]") {
                continue
            }
            // A user-bearing post-auth title can be bare (forwarding-only),
            // have a PTY/notty target, or describe an internal SFTP session.
            let parts = payload.split(separator: "@", omittingEmptySubsequences: false)
            guard (1...2).contains(parts.count), validName(String(parts[0])) else { return nil }
            if parts.count == 2 {
                let destinations = parts[1].split(separator: ",", omittingEmptySubsequences: false)
                guard !destinations.isEmpty, destinations.allSatisfy({ destination in
                    destination == "notty" || destination == "internal-sftp"
                        || (destination.hasPrefix("ttys") && !destination.dropFirst(4).isEmpty
                            && destination.dropFirst(4).allSatisfy(\.isNumber))
                }) else { return nil }
            }
            authenticated.insert(process.pid)
        }
        let parents = Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0.parentPID) })
        var connections = 0
        for pid in authenticated {
            var chain: Set<Int32> = [pid]
            var parent = parents[pid] ?? 0
            var hasAuthenticatedAncestor = false
            while parent > 0 {
                guard chain.insert(parent).inserted else { return nil }
                if authenticated.contains(parent) { hasAuthenticatedAncestor = true }
                parent = parents[parent] ?? 0
            }
            // Internal SFTP children can also carry a post-auth title. Count
            // their authenticated ancestor once, rather than each child.
            if !hasAuthenticatedAncestor { connections += 1 }
        }
        return .init(authenticatedSessionCount: connections)
    }

    private static func validName(_ name: String) -> Bool {
        !name.isEmpty && name.allSatisfy { $0.isLetter || $0.isNumber || "_.-".contains($0) }
    }
}

/// No live evidence backend is enabled: returns unsupported by default. Passing
/// fixture evidence exercises the prototype without asserting live reliability.
/// A backend must prove executable identity, complete visibility and lifecycle
/// behavior before being wired to policy enforcement (A7 validation gate).
public final class SSHSessionReader: SSHSessionObserving {
    private let now: () -> Date
    private let readEvidence: (() -> SignalObservation<[OpenSSHProcessEvidence]>)?

    public init(now: @escaping () -> Date = Date.init,
                readEvidence: (() -> SignalObservation<[OpenSSHProcessEvidence]>)? = nil) {
        self.now = now
        self.readEvidence = readEvidence
    }

    public func observe() -> SignalObservation<SSHSessionSnapshot> {
        guard let readEvidence else { return .unavailable(reason: .unsupported, attemptedAt: now()) }
        switch readEvidence() {
        case .unavailable(let reason, let time): return .unavailable(reason: reason, attemptedAt: time)
        case .available(let processes, let time):
            guard let snapshot = OpenSSHSessionClassifier.classify(processes) else {
                return .unavailable(reason: .unsupported, attemptedAt: time)
            }
            return .available(value: snapshot, observedAt: time)
        }
    }
}

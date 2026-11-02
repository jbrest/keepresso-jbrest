import Foundation

/// A complete count from an authenticated-session backend, not daemon presence.
public struct SSHSessionSnapshot: Equatable, Sendable {
    public var authenticatedSessionCount: Int
    public init(authenticatedSessionCount: Int) {
        self.authenticatedSessionCount = authenticatedSessionCount
    }
}

/// Prototype evidence from console login accounting. This is not a claim about
/// every virtual GUI session. O5 validation gates product use of this signal.
public struct ConsoleSessionSnapshot: Equatable, Sendable {
    public var userNames: Set<String>
    public init(userNames: Set<String>) { self.userNames = userNames }
}

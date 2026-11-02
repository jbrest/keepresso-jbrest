// Adapted from KeepressoCore/ProcessList.swift:33-93, upstream 7ea73a6.
import Foundation
import RuleModel

/// Nonblocking command observation with one background refresh at a time.
/// Unlike the Keepresso adapter, a failed refresh publishes unavailable rather
/// than retaining the last successful commands. The host chooses that policy.
/// Keepresso retention equivalence requires one exclusive consumer: another
/// consumer could start a refresh that replaces an unread successful result.
public final class AsyncPSCommandObserver: ProcessCommandsObserving {
    private let ttl: TimeInterval
    private let now: () -> Date
    /// Acquires raw `ps` output through an injectable fetch, so cache/refresh
    /// logic can be unit-tested without spawning processes.
    private let reader: PSCommandReader
    private let lock = NSLock()
    private var cached: SignalObservation<[String]> = .unavailable(
        reason: .notYetSampled, attemptedAt: Date.distantPast
    )
    private var lastFetch: Date?
    private var isRefreshing = false

    public init(
        ttl: TimeInterval = 3,
        now: @escaping () -> Date = Date.init,
        fetch: @escaping @Sendable () -> String? = PSCommandReader.runPS
    ) {
        self.ttl = ttl
        self.now = now
        self.reader = PSCommandReader(now: now, fetch: fetch)
    }

    public func observe() -> SignalObservation<[String]> {
        let (snapshot, shouldRefresh) = withLock { () -> (SignalObservation<[String]>, Bool) in
            let isStale = lastFetch.map { now().timeIntervalSince($0) >= ttl } ?? true
            let shouldRefresh = isStale && !isRefreshing
            if shouldRefresh { isRefreshing = true }
            return (cached, shouldRefresh)
        }

        if shouldRefresh {
            Task.detached { [weak self] in
                guard let self else { return }
                let fetched = self.reader.observe()
                self.withLock {
                    self.cached = fetched
                    self.lastFetch = self.now()
                    self.isRefreshing = false
                }
            }
        }
        return snapshot
    }

    /// Wraps ``lock`` in a synchronous call so the lock/unlock pair is never
    /// invoked directly from an async context (`NSLock` is `noasync`).
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

}

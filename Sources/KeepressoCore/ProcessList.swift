import Foundation

/// Abstraction over the list of running processes, so a process-matching trigger
/// can be tested without inspecting the real system. Mirrors the other monitor
/// seams (``WorkspaceMonitoring``, ``PowerSourceMonitoring``).
///
/// Unlike ``WorkspaceMonitoring`` (which only sees GUI apps with bundle IDs),
/// this sees *every* process, including command-line tools and background jobs
/// like `node`, `python`, `ffmpeg`, or `claude`.
public protocol ProcessListing: AnyObject {
    /// The full command line of every currently running process.
    var current: [String] { get }
}

/// Real backend over `ps`. Lists each process's full, untruncated command line.
/// Spawning `ps` is not free, and the trigger engine plus the menu can read
/// ``current`` several times a second, so results are cached for ``ttl``
/// seconds: repeated reads reuse one snapshot instead of forking `ps` each
/// time. A process starting or stopping doesn't need sub-second reaction for a
/// keep-awake decision, so a few seconds of staleness is fine. The clock is
/// injectable so the cache can be unit-tested.
///
/// When constructed through ``TriggerFactory``, the fetch is a
/// ``SharedPSSnapshot`` so agent detection shares the same `ps` run. The
/// standalone default still forks a command-only listing of its own.
///
/// ``current`` is read synchronously from the menu's `body` on the main
/// thread, so it must never block on `Process.waitUntilExit()` itself (see the
/// same hazard documented on ``ShellSystemProbe`` and ``PMSetSleepControl``: a
/// blocked main run loop can crash re-entrantly when a virtual display is
/// active). Instead, a stale cache is returned immediately and a refresh is
/// kicked off on a detached task when it goes stale.
public final class PSProcessLister: ProcessListing {
    private let observer: ProcessCommandsObserving
    private let lock = NSLock()
    // Compatibility-only snapshot retained across failed reads, independently
    // of the shared observation cache (U ProcessList.swift:64-78; S2/S4).
    private var retained: [String] = []

    public init(
        ttl: TimeInterval = 3,
        now: @escaping () -> Date = Date.init,
        fetch: @escaping @Sendable () -> String? = PSProcessLister.runPS
    ) {
        observer = AsyncPSCommandObserver(ttl: ttl, now: now, fetch: fetch)
    }

    init(observer: ProcessCommandsObserving) {
        self.observer = observer
    }

    public var current: [String] {
        lock.lock()
        defer { lock.unlock() }
        if case .available(let commands, _) = observer.observe() {
            retained = commands
        }
        // A transient `ps` failure keeps the previous snapshot: an
        // empty one would make a process trigger drop a keep-awake
        // session mid-download or build. Agent monitoring does the
        // same; match it here.
        return retained
    }

    /// The real fetch: spawn `ps` and return its raw output. The default for
    /// ``init(ttl:now:fetch:)``'s `fetch`.
    @Sendable public static func runPS() -> String? {
        PSCommandReader.runPS()
    }
}

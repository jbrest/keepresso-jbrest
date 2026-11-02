// Adapted from KeepressoCore/ProcessList.swift:96-116, upstream 7ea73a6.
import Foundation
import RuleModel

public protocol ProcessCommandsObserving: AnyObject {
    func observe() -> SignalObservation<[String]>
}

/// Synchronous acquisition for a host-owned worker or service loop. UI hosts
/// must call this off the main thread; scheduling and stale-data policy belong
/// to the host rather than this reader.
public final class PSCommandReader: ProcessCommandsObserving {
    private let fetch: @Sendable () -> String?
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init,
                fetch: @escaping @Sendable () -> String? = PSCommandReader.runPS) {
        self.now = now
        self.fetch = fetch
    }

    public func observe() -> SignalObservation<[String]> {
        guard let raw = fetch() else {
            return .unavailable(reason: .readFailed, attemptedAt: now())
        }
        return .available(value: Self.commands(from: raw), observedAt: now())
    }

    public static func commands(from raw: String) -> [String] {
        raw.split(whereSeparator: \.isNewline).map(String.init)
    }

    /// The real fetch: spawn `ps` and return its raw output. The default for
    /// `init(now:fetch:)`'s fetch.
    @Sendable public static func runPS() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        // -a all users, -x include processes without a controlling terminal,
        // -ww no column-width truncation, -o command= full command line, no header.
        process.arguments = ["-axww", "-o", "command="]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let output = String(decoding: data, as: UTF8.self)
            return output.isEmpty ? nil : output
        } catch {
            return nil
        }
    }
}

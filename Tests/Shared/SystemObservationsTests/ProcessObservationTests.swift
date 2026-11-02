import Foundation
import Testing
import RuleModel
import SystemObservations

private final class ProcessFetch: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?
    private var time = Date(timeIntervalSince1970: 0)
    private var count = 0
    init(_ value: String?) { self.value = value }
    var now: Date { lock.withLock { time } }
    var calls: Int { lock.withLock { count } }
    func advance(_ value: String?) { lock.withLock { self.value = value; time = time.addingTimeInterval(4) } }
    @Sendable func fetch() -> String? { lock.withLock { count += 1; return value } }
}

private func eventually(_ check: () -> Bool) async -> Bool {
    for _ in 0..<400 {
        if check() { return true }
        try? await Task.sleep(nanoseconds: 5_000_000)
    }
    return check()
}

@Test func commandReaderDistinguishesEmptyOutputFromFailure() {
    let stub = ProcessFetch("")
    let reader = PSCommandReader(now: { stub.now }, fetch: stub.fetch)
    #expect(reader.observe() == .available(value: [], observedAt: stub.now))
    stub.advance(nil)
    #expect(reader.observe() == .unavailable(reason: .readFailed, attemptedAt: stub.now))
    #expect(PSCommandReader.commands(from: "node x\n\npython y\n") == ["node x", "python y"])
}

@Test func asyncProcessReaderPublishesFailureInsteadOfRetainingCommands() async {
    let stub = ProcessFetch("node x")
    let reader = AsyncPSCommandObserver(now: { stub.now }, fetch: stub.fetch)
    guard case .unavailable(let reason, _) = reader.observe() else {
        Issue.record("Expected initial missing observation"); return
    }
    #expect(reason == .notYetSampled)
    #expect(await eventually {
        if case .available(let commands, _) = reader.observe() { return commands == ["node x"] }
        return false
    })
    #expect(stub.calls == 1)
    stub.advance(nil)
    // The stale available snapshot is returned while refresh starts.
    guard case .available = reader.observe() else { Issue.record("Expected stale snapshot"); return }
    #expect(await eventually {
        if case .unavailable(let reason, _) = reader.observe() { return reason == .readFailed }
        return false
    })
    #expect(stub.calls == 2)
    stub.advance("")
    _ = reader.observe()
    #expect(await eventually {
        if case .available(let commands, _) = reader.observe() { return commands.isEmpty }
        return false
    })
    #expect(stub.calls == 3)
}

@Test func richProcessObservationPreservesCacheAndCommandProjection() {
    let stub = ProcessFetch(" 1 0 0.0 ?? /bin/node server.js\nmalformed\n2 1 1.0 ttys0 python run.py")
    let shared = SharedPSSnapshot(now: { stub.now }, run: stub.fetch)
    let raw = shared.fetchRaw()
    #expect(raw != nil)
    #expect(shared.fetchCommandListing() == "/bin/node server.js\npython run.py")
    #expect(stub.calls == 1)
    #expect(shared.observe() == .available(value: raw!, observedAt: stub.now))
    stub.advance(nil)
    #expect(shared.observe() == .unavailable(reason: .readFailed, attemptedAt: stub.now))
    // Upstream retries a failed rich fetch even within TTL; preserve this.
    #expect(shared.fetchRaw() == nil)
    #expect(stub.calls == 3)
}

@Test func realProcessReaderReadOnlySmoke() {
    guard case .available(let commands, _) = PSCommandReader().observe() else {
        Issue.record("Read-only ps failed"); return
    }
    #expect(!commands.isEmpty)
    print("Process reader smoke: available count=\(commands.count)")
}

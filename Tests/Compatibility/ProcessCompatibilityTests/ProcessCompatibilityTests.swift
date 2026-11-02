import Foundation
import Testing
@testable import KeepressoCore

@Test func processMatchingRetainsUpstreamSubstringSemantics() {
    let snapshots = [[], ["NODE server.js", "/bin/python3 work.py", "café task"], ["sshd: user", "foo\tbar"]]
    for query in ["", " ", "\t", "\n", " node ", "PYTHON", "sshd:", "café", "missing"] {
        for commands in snapshots {
            let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
            let expected = !needle.isEmpty && commands.contains { $0.lowercased().contains(needle) }
            #expect(ProcessTrigger.matches(query, in: commands) == expected)
        }
    }
}

private final class Listing: ProcessListing {
    var current = ["node build.js"]
}

@Test func processRuleEditsApplyToRetainedSnapshotImmediately() {
    let listing = Listing()
    let trigger = ProcessTrigger(query: "node", monitor: listing)
    #expect(trigger.isSatisfied())
    trigger.query = "python"
    #expect(!trigger.isSatisfied())
    listing.current = ["python train.py"]
    #expect(trigger.isSatisfied())
}

private final class ScriptedObservation: ProcessCommandsObserving {
    var result: SignalObservation<[String]> = .unavailable(reason: .notYetSampled, attemptedAt: Date())
    func observe() -> SignalObservation<[String]> { result }
}

@Test func failedProcessAcquisitionStillUsesCurrentQueryAndSuccessfulEmptyClearsIt() {
    let reader = ScriptedObservation()
    let listing = PSProcessLister(observer: reader)
    let trigger = ProcessTrigger(query: "node", monitor: listing)
    #expect(!trigger.isSatisfied())
    reader.result = .available(value: ["node build.js"], observedAt: Date())
    #expect(trigger.isSatisfied())
    reader.result = .unavailable(reason: .readFailed, attemptedAt: Date())
    #expect(trigger.isSatisfied())
    trigger.query = "python"
    #expect(!trigger.isSatisfied())
    trigger.query = "build.js"
    #expect(trigger.isSatisfied())
    reader.result = .available(value: [], observedAt: Date())
    #expect(listing.current.isEmpty)
    #expect(!trigger.isSatisfied())
}

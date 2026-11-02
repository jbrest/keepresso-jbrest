import Foundation
import Testing
import RuleModel
import SystemObservations

@Test func sshListenerAndPreauthFixturesAreNotAuthenticatedSessions() {
    let evidence: [OpenSSHProcessEvidence] = [
        .init(pid: 1, executable: .sshd, title: "/usr/sbin/sshd -i"),
        .init(pid: 2, executable: .session, title: "sshd-session: [accepted]"),
        .init(pid: 3, executable: .session, title: "sshd-session: alice [priv]"),
        .init(pid: 4, executable: .authentication, title: "sshd-auth: [session-auth]"),
        .init(pid: 5, executable: .sshd, title: "sshd: alice [preauth]"),
        .init(pid: 6, executable: .sshd, title: "sshd: [net]"),
        .init(pid: 7, executable: .sshd, title: "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups")
    ]
    #expect(OpenSSHSessionClassifier.classify(evidence)?.authenticatedSessionCount == 0)
    #expect(OpenSSHSessionClassifier.classify([])?.authenticatedSessionCount == 0)
}

@Test func sshAuthenticatedFixturesCoverLegacySplitNoPTYAndSFTP() {
    let evidence: [OpenSSHProcessEvidence] = [
        .init(pid: 1, executable: .sshd, title: "sshd: alice@ttys000"),
        .init(pid: 2, executable: .session, title: "sshd-session: bob@notty"),
        .init(pid: 3, executable: .session, title: "sshd-session: root"),
        .init(pid: 4, executable: .session, title: "sshd-session: carol@ttys001,ttys002"),
        .init(pid: 5, parentPID: 2, executable: .session, title: "sshd-session: bob@internal-sftp")
    ]
    #expect(OpenSSHSessionClassifier.classify(evidence)?.authenticatedSessionCount == 4)
}

@Test func sshUnknownTitlesAndInvalidSnapshotsRemainUnsupported() {
    for title in ["sshd-session", "sshd-session: ", "sshd-session: [new-state]", "sshd-session: alice@future-terminal"] {
        #expect(OpenSSHSessionClassifier.classify([.init(pid: 1, executable: .session, title: title)]) == nil)
    }
    let row = OpenSSHProcessEvidence(pid: 1, executable: .session, title: "sshd-session: alice")
    #expect(OpenSSHSessionClassifier.classify([row, row]) == nil)
    #expect(OpenSSHSessionClassifier.classify([.init(pid: 1, parentPID: 1, executable: .session,
                                                    title: "sshd-session: alice")]) == nil)
}

@Test func sshArbitraryCommandStringsCannotSupplyExecutableIdentity() {
    #expect(OpenSSHSessionClassifier.classify([
        .init(pid: 1, executable: .other, title: "echo sshd-session: alice@ttys000")
    ])?.authenticatedSessionCount == 0)
}

@Test func sshReaderDefaultsToUnsupportedAndPreservesEvidenceFailures() {
    let at = Date(timeIntervalSince1970: 1)
    #expect(SSHSessionReader(now: { at }).observe() == .unavailable(reason: .unsupported, attemptedAt: at))
    let failed = SSHSessionReader(readEvidence: { .unavailable(reason: .permissionDenied, attemptedAt: at) })
    #expect(failed.observe() == .unavailable(reason: .permissionDenied, attemptedAt: at))
    let fixture = SSHSessionReader(readEvidence: { .available(value: [
        .init(pid: 1, executable: .session, title: "sshd-session: alice@notty")
    ], observedAt: at) })
    #expect(fixture.observe() == .available(value: .init(authenticatedSessionCount: 1), observedAt: at))
}

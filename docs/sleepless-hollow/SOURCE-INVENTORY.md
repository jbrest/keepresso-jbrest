# Sleepless Hollow: source inventory and provenance

Date: 2 November 2026, revised the same day (decision P7). Status: planning
inventory. Fill in the "Done" table at the end as work lands (invariants I3 and
I4 in MIGRATION-PLAN.md).

Revisions:
- `U` = `upstream/main` at `7ea73a6`.
- `A` = tag `archive/headless-in-keepresso-2026-11-02` (commit `53d8240`).

Line numbers are hints and may drift, so search by name. Port types:
- **verbatim**: copied with access and naming changes only.
- **adapted**: same behavior, restructured.
- **redesigned**: written against the new design, using the source as reference.

## Moved out of KeepressoCore in Stage A (with wrappers)

These files change in Stage A. The logic moves to the shared module, and the
Keepresso type stays behind as a wrapper with its two-state adapter. Labels,
localization, factories, the `Trigger` protocol and saved Codable shapes stay in
`KeepressoCore`.

| Source (rev U) | What moves | Destination | What stays in KeepressoCore |
| --- | --- | --- | --- |
| `Trigger.swift` | `PowerSourceTrigger.Match` matching (~L52-95); `ProcessTrigger` matching (~L198); `CombineMode` (~L313) | RuleModel, RuleEvaluation | Trigger classes as wrappers; labels; `Match` raw values (alias or mapped) |
| `TimeWindow.swift` | `TimeWindowRule` value and `TimeWindowTrigger` boundary logic | RuleModel, RuleEvaluation | Codable shape, labels and day summaries; trigger wrapper |
| `CPULoad.swift` | `HostCPULoadReader`; smoothing state machine and constants | SystemObservations; RuleEvaluation | `CPULoadTrigger` wrapper |
| `NetworkThroughput.swift` | `GetifaddrsThroughputReader`; smoothing, units and release fraction | SystemObservations; RuleEvaluation | `NetworkThroughputTrigger` wrapper |
| `PowerSource.swift` | `PowerSourceSnapshot` and reader | RuleModel; SystemObservations | Type alias if needed |
| `ProcessList.swift`, `SharedPSSnapshot.swift` | Process listing and parsing | SystemObservations | Type aliases or wrappers |
| `Thermal.swift`, `BatteryLowPower.swift` | Readings only, if O8 adopts safety | SystemObservations | `ThermalGuard` and its policy |

Tests: the originals in `Tests/KeepressoCoreTests` keep running against the
wrappers unchanged. Pure-logic cases may also be copied into the shared module's
tests. `PresetTests` must keep passing; the upstream SSH preset itself is not
changed in Stage A (see F4).

## Seeded from Keepresso's helper code (read-only until Stage E)

These files are not edited before Stage E. PowerControl and ServiceSupport copy
behavior from them, with provenance recorded (I4) and checked after each rebase
(I5).

| Source (rev U) | What is taken | Destination | Port type |
| --- | --- | --- | --- |
| `PowerAssertion.swift` | IOPMAssertion wrapper | PowerControl assertion mechanism | adapted |
| `HelperEngine.swift` | Restore markers, `FileRestoreState`, the `disablesleep` apply/restore path, `HelperShutdownPolicy` | PowerControl journal and disablesleep mechanism; SleeplessRuntime idle exit | redesigned |
| `HelperService.swift` | Code-signing requirement construction (~L144), XPC client patterns | ServiceSupport | redesigned |
| `HelperRecovery.swift` | Recovery state primitives | ServiceSupport | adapted |
| `Preset.swift` (~L60-68) | Comments on the `sshd:` versus `sshd-session` process names | SSH reader (reference only) | reference |

Seeded tests to adapt:
- `HelperShutdownPolicyTests`, `HelperRecoveryTests`;
- the relevant cases from `HelperEngineTests`.

## Fork-only sources from the archive (port with fixes)

| Source (rev A) | Lines | Destination | Port type |
| --- | --- | --- | --- |
| `KeepressoCore/HeadlessPolicy.swift` | 139 | SleeplessContracts `PolicyDTO` v1 | redesigned (versioned; no shared types on the wire) |
| `KeepressoCore/HeadlessPolicyStore.swift` | 234 | SleeplessRuntime | adapted |
| `KeepressoCore/HeadlessPolicyEvaluator.swift` | 154 | Generic parts to RuleEvaluation; aggregation to SleeplessRuntime | redesigned |
| `KeepressoCore/HeadlessSupervisor.swift` | 286 | SleeplessRuntime | adapted, with fixes F1, F2, F5 |
| `KeepressoCore/HeadlessSystemSignalSampler.swift` | 138 | SleeplessRuntime composition over SystemObservations | redesigned (no static calls into Keepresso trigger classes) |
| `KeepressoCore/HeadlessDiagnostics.swift` | 210 | SSH classifier to SystemObservations (fix F4); capture and logging to ServiceSupport | redesigned |
| `KeepressoCore/HelperPeerPolicy.swift` | 135 | ServiceSupport | adapted; keep the `Info.plist` `CFBundleExecutable` fix |
| `KeepressoCore/HelperService.swift` (fork parts) | ~360 changed | `HelperAdministratorIdentity` and `HelperAdministratorAuthorization` (~L159-230) to ServiceSupport, keeping the `getgrouplist` fix | adapted |
| `keepresso-helper/main.swift` | 563 | Reference for `sleepless-helper`: listener, `shouldAccept`, idle exit | redesigned, with fix F3 |
| `Tests/Fixtures/HelperPeerProbe/` | 48 | ServiceSupport test fixture | verbatim |
| `tools/headless-ssh-client-test.py` | 67 | Kept for SSH validation in A2 and D3 | verbatim |
| `tools/clean-headless-test-state.sh` | 262 | Rewritten for SH identity in D2 | redesigned |
| `tools/localization/catalog_headless_*.py` | ~915 | Reference for SH strings in D1 | reference |

Archived tests to port and adapt:
- `HeadlessPolicyTests`, `HeadlessPolicyStoreTests`, `HeadlessPolicyEvaluatorTests`;
- `HeadlessSupervisorTests`, `HeadlessSystemSignalSamplerTests`, `HeadlessDiagnosticsTests`;
- `HelperPeerPolicyTests` (fork version), `HelperEmbeddedPeerTests`;
- the fork additions to `HelperConnectionTests`.

## Known defects to fix during the port

Each one gets a regression test in the stage named.

| ID | Defect (rev A) | Fix | Stage |
| --- | --- | --- | --- |
| F1 | `prepareForRemoval` only requires an administrator when a policy is enabled. A non-admin can therefore set `removalPrepared` and block admins until the helper exits. | Starting removal always requires an administrator | C |
| F2 | Cancelling removal leaves a previously enabled policy disabled | Cancel restores the accepted policy that existed before preparation | C |
| F3 | `restoreAtLaunch()` runs before `supervisor.start()`, so an update briefly releases and then re-acquires the hold | Reconcile the journal after the first evaluation (see ARCHITECTURE.md, PowerControl) | B2, C |
| F4 | The SSH classifier counts any `sshd:` or `sshd-session` process, including pre-auth connections | Count authenticated sessions only; the method is validated in A2 | A2 |
| F5 | Removal during an active `disablesleep` hold is unproven and suspected to leave the setting changed | The removal transaction verifies release before unregistering; installed test in D3 | C, D3 |
| F6 | No thermal or battery safety in the service | Per O8 | C |

Upstream note: the upstream SSH preset uses the same process-name match
(`Preset.swift` ~L68), so F4 may also affect Keepresso. If A2 confirms it, that
fix is a candidate small upstream PR for Stage F. The peer-policy and
`getgrouplist` defects were introduced in fork-only code and do not exist
upstream.

## Deliberately not carried forward

- All Headless changes to Keepresso's app shell: about 2,955 lines over 30 files
  at rev A, including the `PreferencesView` section (+721), the `WelcomeView` and
  `SetupView` changes, and the Headless strings in 15 languages.
- The `HeadlessTest` target and plist in `project.yml`, and the helper's
  `HeadlessTest-Info.plist`.
- Protocol 16 extensions to Keepresso's helper XPC protocol. SH has its own
  service.
- `tools/architecture/check_boundaries.py`. SwiftPM dependencies enforce the
  boundaries instead.
- The archived Codex modular proposal targets `KeepressoContracts`,
  `KeepressoRuntime`, `ProductAdapters` and `SharedSupport`. Their concerns
  belong to Stages E and G.

## Stays Keepresso-only

Everything in `KeepressoCore` not listed above stays where it is and is not
edited. That includes:
- `SessionController` and session modes;
- all other triggers (calendar, Bluetooth, gaming, VPN, volume, captive
  network);
- SMC and fans, AWDL, keyboard lock, wake schedules, closed-display handling,
  and agent and automation integration.

## Done (fill in as work lands)

| Unit | Source | Rev | Moved, seeded or ported | Commit |
| --- | --- | --- | --- | --- |
| | | | | |

# Sleepless Hollow: decisions

Date started: 2 November 2026. Add new entries at the end of each section and
never renumber. When an open item is settled, move it to "Decided" with the
date and who decided, then update the affected doc.

## Decided by jbrest

| ID | Decision | Date |
| --- | --- | --- |
| P1 | SH is a standalone app with its own background service and identity. Keepresso's UI is unchanged. | 2026-11-02 |
| P2 | The earlier in-Keepresso Headless work is archived at tag `archive/headless-in-keepresso-2026-11-02`. New work starts from `upstream/main` on `sh/foundation`. | 2026-11-02 |
| P3 | Superseded by P7. (Was: build the shared modules first and the Keepresso adapter layer later.) | 2026-11-02 |
| P4 | jbrest maintains SH in perpetuity, including backend issues caused by SH features or by bugs SH exposes. gyorgysh never needs to touch SH. | 2026-11-02 |
| P5 | Nothing is pushed or posted upstream without jbrest's explicit approval. | 2026-11-02 |
| P6 | Codex reviews this plan and does most of the implementation. Claude Code reviews at the checkpoints in NOTES.md. | 2026-11-02 |
| P7 | Build the Keepresso adapter, including the three-state to two-state adapter, while modularizing the rules and observations: each condition moves and is adapted in one step. Keepresso's privileged helper keeps its own code until Stage E. SH's power and service modules are built fresh, seeded from it. Upstream PR #31 is not a concern. | 2026-11-02 |
| P8 | S2 adapter contract: preserve reader/cache/state behavior and evaluate current queries or thresholds against retained data when readings fail; last-verdict fallback alone is forbidden. | 2026-11-02 |
| P9 | S3 scope: settle only Stage A blockers now; record later stage gates without designing them; review before B1; use separate upstream-fix worktrees; stop for security-critical findings; use a small plain-Python import check, no rg or forbidden-import build experiments. | 2026-11-02 |
| P10 | S4 state comments: one or two source-citing lines only for compatibility-only or mixed state, with the same state listed in condition migration notes; no classification comment for purely operational state. | 2026-11-02 |
| P11 | S5 parity: capture baseline test identities; every identity remains and passes after a move. Deleting or renaming requires approval; additional tests do not substitute for baseline tests. | 2026-11-02 |
| P12 | S6: TTLCache moves to SystemObservations at A4; KeepressoCore retains its name for unchanged users. | 2026-11-02 |
| P13 | S7 stable IDs: A1 scaffolding, A2 power, A3 time, A4 CPU/cache, A5 throughput, A6 processes, A7 SSH/console, A8 optional thermal. | 2026-11-02 |
| P14 | S8: stale retained readings without user-visible freshness are a possible future Keepresso improvement, not a bug or a refactor behavior change. | 2026-11-02 |

## Technical decisions (proposed by Claude Code; open to Codex challenge)

| ID | Decision | Reason |
| --- | --- | --- |
| T1 | Two tracks (see P7). Rules and observations move with wrappers now. Helper code is seeded for SH and adopted by Keepresso in Stage E. | Rule and observation files had no upstream commits in 60 days, except one each for process listing. Helper files had 20 file touches over 13 distinct commits from 2026-09-03 through 2026-11-02 and need installed testing. |
| T2 | SwiftPM target dependencies enforce module boundaries | The compiler checks project dependencies; a small plain-Python framework/product import check supplements it |
| T3 | Each product owns its saved and wire formats; shared types are mapped, not serialized directly | Shared type changes cannot silently break files or protocols |
| T4 | Three-state verdicts with Kleene any/all; unavailable is never false | Required for honest headless status |
| T5 | PowerControl covers keep-awake holds only | AWDL, keyboard lock and fans are not power control and SH doesn't need them |
| T6 | No `SharedSupport` module until a second real consumer exists | Avoids a grab-bag |
| T7 | SH helper protocol starts at version 1 under its own identity | No coupling to upstream protocol 12 or archived fork protocol 16 |
| T8 | The SH app is built from its own XcodeGen spec (`SleeplessHollow.yml`) | Leaves upstream `project.yml` untouched |
| T9 | The SH app depends only on contracts and ServiceSupport, not on the runtime or rule modules | Only the service evaluates; the UI cannot drift from it |
| T10 | Launch reconciliation runs after the first evaluation | Addresses restore/reacquire ordering (F3); mechanism-specific continuity still needs testing |

## Open

| ID | Question | Settled in | Notes |
| --- | --- | --- | --- |
| O1 | Power mechanism: IOPMAssertion, `pmset disablesleep`, or both for different situations | B1 | gyorgysh noted on upstream #21 that restoring the sleep setting caused compatibility problems with other software. Assertions leave no restore debt and stack independently. `disablesleep` is one machine-wide setting that Keepresso's helper may also set and restore, so the two helpers could undo each other. Behavior with no login is untested. |
| O2 | SH bundle identifiers, service name and signing team | D1 | `sh.gyorgy.*` must not be used. Team `DUBDVK9FC2` was used for archive testing; confirm it is jbrest's. |
| O3 | Final product name ("Sleepless Hollow" is provisional) | Before D1 | |
| O4 | Policy-change authentication: admin group only, or fresh authentication per change; interaction with autosave | C | Archive: admin group membership via `getgrouplist` |
| O5 | Console-session condition: any qualifying console user or a selected account; fast user switching; virtual sessions | A7 | See PRODUCT.md |
| O6 | Status-only menu-bar item in addition to the window | D1 | |
| O7 | Disabling keeps the service installed (proposed) | D1 | |
| O8 | Thermal and battery safety: whether, thresholds, and how it is reported | C | Keepresso has `ThermalGuard`; SH runs unattended |
| O9 | Remote-lockout warning when a policy could stop a remote Mac from being reachable | D1 | |
| O10 | What SH does with an aggregate `unknown`: hold, release, or keep the last known state | C | Must be shown in status |
| O11 | How each Keepresso compatibility adapter preserves retained data, current-parameter evaluation and Bool results | A, per condition | Fill in the table below as each condition moves |
| O12 | Long-term home for SH: this fork or its own repository. GPLv3 applies either way, since SH is derived from Keepresso. | After D | |
| O13 | First-run condition list: empty (proposed) or a visible preset | D1 | |

## O11: compatibility behavior per condition

Record how each Keepresso trigger behaved with a missing or unknown reading
before its move, and confirm the adapter reproduces it. Cite the source line.

| Condition | Pre-move behavior on missing reading | Source | Adapter preserves |
| --- | --- | --- | --- |
| Power source (A2) | Missing IOKit blob produces unknown provider, false charging, false hasBattery, nil percentage. AC/battery compare provider; charging uses isCharging even if provider is unknown. No cached last sample. | U 7ea73a6 PowerSource.swift:57-59; Trigger.swift:88-94 | The same fallback snapshot and predicates, with shared unknown mapped to false for AC/battery; current match and reading are checked on every isSatisfied call. |
| Time window (A3) | Injected calendar/date evaluated on each call; missing date components return false | U 7ea73a6 TimeWindow.swift:77-97 | Shared unknown maps to false; current fields, injected clock/calendar, equal endpoints and original Codable stay unchanged |
| CPU load (A4) | Failed reads keep the smoothed average and reevaluate the current threshold on tick; initial missing data is false; nonpositive thresholds reset state | U 7ea73a6 CPULoad.swift:124-153 | Shared unavailable is unknown; Core explicitly requests retained-average reevaluation. Smoothing, hysteresis and polling timing remain unchanged |
| Network throughput (A5) | Failed reads retain average and reevaluate current threshold on tick; initial nil is false; invalid thresholds reset | U 7ea73a6 NetworkThroughput.swift:147-174 | Shared unavailable stays unknown; Core explicitly reevaluates retained average. Units, release fraction, labels and cadence unchanged |
| Process | | | |

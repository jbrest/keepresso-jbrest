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

## Technical decisions (proposed by Claude Code; open to Codex challenge)

| ID | Decision | Reason |
| --- | --- | --- |
| T1 | Two tracks (see P7). Rules and observations move with wrappers now. Helper code is seeded for SH and adopted by Keepresso in Stage E. | Rule and observation files had no upstream commits in 60 days, except one each for process listing. Helper files had 18 and need installed testing. |
| T2 | SwiftPM target dependencies enforce module boundaries | The compiler checks them; no `rg`-based script |
| T3 | Each product owns its saved and wire formats; shared types are mapped, not serialized directly | Shared type changes cannot silently break files or protocols |
| T4 | Three-state verdicts with Kleene any/all; unavailable is never false | Required for honest headless status |
| T5 | PowerControl covers keep-awake holds only | AWDL, keyboard lock and fans are not power control and SH doesn't need them |
| T6 | No `SharedSupport` module until a second real consumer exists | Avoids a grab-bag |
| T7 | SH helper protocol starts at version 1 under its own identity | No coupling to Keepresso's protocol 16 |
| T8 | The SH app is built from its own XcodeGen spec (`SleeplessHollow.yml`) | Leaves upstream `project.yml` untouched |
| T9 | The SH app depends only on contracts and ServiceSupport, not on the runtime or rule modules | Only the service evaluates; the UI cannot drift from it |
| T10 | Launch reconciliation runs after the first evaluation | Fixes the update handover gap (F3) |

## Open

| ID | Question | Settled in | Notes |
| --- | --- | --- | --- |
| O1 | Power mechanism: IOPMAssertion, `pmset disablesleep`, or both for different situations | B1 | gyorgysh noted on upstream #21 that restoring the sleep setting caused compatibility problems with other software. Assertions leave no restore debt and stack independently. `disablesleep` is one machine-wide setting that Keepresso's helper may also set and restore, so the two helpers could undo each other. Behavior with no login is untested. |
| O2 | SH bundle identifiers, service name and signing team | D1 | `sh.gyorgy.*` must not be used. Team `DUBDVK9FC2` was used for archive testing; confirm it is jbrest's. |
| O3 | Final product name ("Sleepless Hollow" is provisional) | Before D1 | |
| O4 | Policy-change authentication: admin group only, or fresh authentication per change; interaction with autosave | C | Archive: admin group membership via `getgrouplist` |
| O5 | Console-session condition: any qualifying console user or a selected account; fast user switching; virtual sessions | A2 | See PRODUCT.md |
| O6 | Status-only menu-bar item in addition to the window | D1 | |
| O7 | Disabling keeps the service installed (proposed) | D1 | |
| O8 | Thermal and battery safety: whether, thresholds, and how it is reported | C | Keepresso has `ThermalGuard`; SH runs unattended |
| O9 | Remote-lockout warning when a policy could stop a remote Mac from being reachable | D1 | |
| O10 | What SH does with an aggregate `unknown`: hold, release, or keep the last known state | C | Must be shown in status |
| O11 | How Keepresso's two-state adapter maps `unknown`, per condition type, reproducing current behavior exactly | A, per condition | Fill in the table below as each condition moves |
| O12 | Long-term home for SH: this fork or its own repository. GPLv3 applies either way, since SH is derived from Keepresso. | After D | |
| O13 | First-run condition list: empty (proposed) or a visible preset | D1 | |

## O11: two-state mapping per condition

Record how each Keepresso trigger behaved with a missing or unknown reading
before its move, and confirm the adapter reproduces it. Cite the source line.

| Condition | Pre-move behavior on missing reading | Source | Adapter maps `unknown` to |
| --- | --- | --- | --- |
| Power source | | | |
| Time window | (no reading; always known) | | |
| CPU load | | | |
| Network throughput | | | |
| Process | | | |

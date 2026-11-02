# NOTES: running status

Branch `sh/foundation`. Plan and docs: [docs/sleepless-hollow/](docs/sleepless-hollow/README.md).
This file is fork-only; it holds what's done, what's next and open questions.
Update it after each milestone.

## Current stage

Claude accepted A3/A4. A5 throughput extraction complete; A6 processes next.
Stop after A6 for Claude Code review before A7.

## Done

- 2026-11-02: A5 throughput extraction complete. Applied A3/A4 review comments:
  CPU compatibility comment now describes behavior at the fallback branch;
  restored moved CPU reader comments. Corrected the inventory classification.
  U2 remains suspected: a decreased busy count does not logically imply a
  decreased total, since idle increments may offset it. Long sampling gaps
  could matter; neither required gap nor macOS reachability is established.
  Throughput guards byte subtraction. Evidence: docs/sleepless-hollow/evidence/A5.md.

- 2026-11-02: A4 CPU/cache extraction complete. Original CPU reader injection
  and smoothing test seams remain. TTLCache has one shared definition, re-exported
  under its existing name. All 1,177 baseline identities retained; 1,208 tests
  pass. Package and unsigned consumer builds, import guard and I1 pass.
  Evidence: docs/sleepless-hollow/evidence/A4.md.

- 2026-11-02: A3 complete, including restoration of retained upstream power API
  comments. Original TimeWindowRule Codable and presentation remain; shared
  condition/evaluation delegates preserve current behavior. All 1,177 baseline
  identities retained; 1,200 tests pass; package and unsigned consumer builds
  pass. Import check and I1 diff pass. Evidence: evidence/A3.md.

- 2026-11-02: A2 power-source extraction complete with original Keepresso names,
  injected monitor seam and Match Codable/raw values intact. Shared snapshot has
  one definition, exposed by re-export; shared reader/evaluator report explicit
  availability. O11 and source review/provenance tables updated; no new confirmed
  upstream defect. RuleVerdict rename and the naming rule are in this step.
- A2 validation: 1,188 main tests plus 8 separate XPC tests passed (1,196 total).
  All 1,177 baseline identities retained, with 19 additions since baseline.
  Package and unsigned app/widget/helper/CLI/MCP builds passed. The seven-file
  import check passed, protected I1 diff is empty, original Core tests unchanged.
  Real power-reader smoke: available, provider ac, charging false, battery false.
  Durable evidence: docs/sleepless-hollow/evidence/A2.md.

- 2026-11-02: Applied Claude's A1 review items 1-4. Removed unnecessary shared
  library products; targets remain. Re-ran the non-quiet unsigned app build:
  exit 0 and BUILD SUCCEEDED. Full package/test baseline remains green.
  Durable summary: docs/sleepless-hollow/evidence/A1.md. Every step now requires
  import, identity and I1 checks plus a committed short evidence summary.

- 2026-11-02: A1 scaffolding complete. RuleModel, RuleEvaluation and
  SystemObservations are actual SwiftPM targets/products; KeepressoCore depends
  on and re-exports them. No existing runtime/condition source was moved.
- A1 validation: all 1,177 baseline identities retained; 1,178 tests in the main
  run plus 8 separately scheduled XPC tests passed (1,186 total, 9 new tests).
  Package build and unsigned app/widget/helper/CLI/MCP consumer build passed.
  The protected I1 source/project diff is empty; existing Core tests unchanged.
- Import allowlist check passed. Baseline identity checker also rejects a
  missing required identity; import parsing covers standard/exported/scoped
  imports. No forbidden-import build experiments were performed.

- 2026-11-02: Captured upstream baseline and test identities; package tests and
  unsigned app/widget/helper/tool consumer build passed. Stage 0 is closed.

- 2026-11-02: Committed the uncommitted modular proposal drafts on
  `codex/headless-lifecycle` (`53d8240`). Tagged them as
  `archive/headless-in-keepresso-2026-11-02`.
- 2026-11-02: Created `sh/foundation` from `upstream/main` `7ea73a6`.
- 2026-11-02: Wrote the planning set in `docs/sleepless-hollow/`.
- 2026-11-02: Added the upstream code review rule (I7) and the candidate
  table below.
- 2026-11-02: Codex review settled by jbrest after Claude Code review, per
  CODEX-BRIEF.md Phase 2. Applied S1-S8, recorded P8-P14 and later-stage gates.
- 2026-11-02: Revised the plan per decision P7. The Keepresso adapter is built
  while modularizing the rules and observations, one condition at a time.
  Keepresso's helper is left alone until Stage E.

## Next

1. A6 process acquisition/matching and compatibility adapter.
2. Stop for Claude Code review after A6, before A7.

## Review checkpoints (Claude Code)

Stop and ask jbrest for a Claude Code review at each of these points:

1. Stage 0 review settled on 2 November in CODEX-BRIEF.md Phase 2.
2. After A1, before A2; then after A2 (power source moved and adapted). This sets the pattern
   for every later condition.
3. After A4 (CPU load, the first condition with smoothing state, TTLCache and
   S4 comments).
4. After A6 (processes: the first compatibility-only state, and shared
   process acquisition).
5. At the end of Stage A.
6. Before B1 experiments, and after B1 results before PowerControl is built.
7. Before any installed test in Stage D.
8. Any time an invariant in MIGRATION-PLAN.md would have to be broken, or an
   approach has failed twice.

## Upstream fix candidates

Per "Reviewing touched upstream code" in MIGRATION-PLAN.md. Nothing here is
fixed on `sh/foundation`. Submission needs jbrest's approval.

| ID | File:line (rev) | Problem and user effect | Severity | Status | Test / branch |
| --- | --- | --- | --- | --- | --- |
| U1 | `Sources/KeepressoCore/Preset.swift`:68 (`7ea73a6`) | The "Remote Session (SSH)" preset matches any process containing `sshd:` or `sshd-session`. That may include connections that have not logged in yet, so a scanner probing port 22 could keep the Mac awake while the login grace period runs. macOS launches sshd per connection, so the actual pre-auth process names need checking. | low (if real) | suspected | Check in Stage A step 7 |
| U2 | `Sources/KeepressoCore/CPULoad.swift`:54-58 (`7ea73a6`) | Delta calculation guards increasing total ticks but subtracts unsigned busy ticks without checking their order. A decreasing busy count with increasing total could trap; idle increments can offset a busy decrease. Long gaps spanning counter wraps are a candidate scenario, but timing and macOS reachability are unproven. Preserved in extraction. | low (real-world reachability unproven) | suspected, source review only | Separate upstream-fix regression and counter-wrap/reset investigation before proposing a fix |

## Possible Keepresso improvements (not bugs)

| ID | Existing behavior | Possible later improvement | Status |
| --- | --- | --- | --- |
| K1 | Process and throughput conditions can use retained data indefinitely during repeated reading failures, without showing staleness | Show freshness and optionally bound stale-data retention, only if gyorgysh wants it | Future option; unchanged by refactoring |

## Baseline

Captured on 2 November 2026 from upstream source `7ea73a6`, with only planning
changes on the foundation branch:

- `swift build`: passed for all package products.
- `swift test --skip HelperConnectionTests`: 1,169 tests passed.
- `swift test --filter HelperConnectionTests`: 8 tests passed.
- Total: 1,177 baseline identities, saved in
  `docs/sleepless-hollow/baseline/tests-7ea73a6.txt`.
- Swift 6.3.3, Xcode 26.6 (17F113), macOS SDK 26.5, macOS 26.5 (25F71), arm64.
- XcodeGen generated the ignored project. Unsigned Debug Keepresso scheme built
  with embedded widget, helper, CLI and MCP. Nothing installed or launched.
- Environment and source hashes:
  `docs/sleepless-hollow/baseline/environment-7ea73a6.json`.
- Full run logs: `/tmp/sh-baseline-{build,core-tests,xpc-tests,app-build}.log`.
  Temporary logs are not retained release evidence; the identity list and summary
  are committed. I1 protected source/project diff is empty.


## Open questions

See [DECISIONS.md](docs/sleepless-hollow/DECISIONS.md), section "Open". The
ones that block early stages:
- O11: fill in the two-state mapping table as each condition moves (Stage A).
- O5: console-session detection method (Stage A step 7).
- O1: power mechanism (B1, which needs jbrest for reboots and logouts).

## Watch

- Upstream PR #31 reworks `SessionController`. It doesn't touch the files Stage
  A moves, and jbrest has said it is not a concern.
- Nothing on `sh/foundation` or the archive tag has been pushed to `origin`.

## A1 implementation note

The first scaffold build exposed a naming collision: exporting a generic
`Observation` type shadows Apple's Observation module in existing @Observable
macro expansions. The shared value is named `SignalObservation` instead, with
no change to the planned observation semantics or existing Keepresso source.

## A1 review evidence

- Logs: `/tmp/sh-a1-build.log`, `/tmp/sh-a1-core-tests.log`,
  `/tmp/sh-a1-xpc-tests.log`, `/tmp/sh-a1-app-build.log`.
- Current identity list: `/tmp/sh-a1-test-identities.txt`; compare with committed
  baseline using `python3 tools/check-baseline-tests.py BASELINE CURRENT`.
- Framework/product guard: `python3 tools/check-shared-imports.py`.
- SignalObservation and its reason values are not Codable; products own wire
  formats. No CombineMode migration or live reader implementation is in A1.
- No compatibility-only/mixed state introduced, so S4 classification comments
  are not needed yet. No push, upstream contact, app launch or live service/
  policy mutation occurred.

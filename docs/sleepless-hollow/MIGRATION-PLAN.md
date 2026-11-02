# Sleepless Hollow: migration and staging plan

Date: 2 November 2026, revised the same day (decision P7). Status: proposed,
pending Codex review. Current stage: 0 (see [NOTES.md](../../NOTES.md)).

## Strategy

There are two tracks, chosen by how risky and how actively changed the code is.

**Rules and observations: move and adapt now.** These files have had no upstream
commits in the last 60 days. The process listing files are the only exception,
with one each. Each condition type moves out of `KeepressoCore` into the shared
modules. In the same step:
- Keepresso's existing type becomes a thin wrapper over the shared code.
- That condition's three-state to two-state adapter is written.

Keepresso's existing tests must pass unchanged before the next condition moves.
The result:
- no duplicated logic;
- Keepresso's ~1,200 tests guard the shared code from the start;
- every shared boundary has two real consumers while it is being designed.

**Privileged helper: build fresh for SH; adopt in Keepresso later.**
Keepresso's helper files changed 18 times upstream in 60 days
(`HelperEngine` 6, `HelperService` 8, `HelperRecovery` 4). They run as root, and
verifying a change to them needs an installed Keepresso test. PowerControl and
ServiceSupport are therefore built for SH, seeded from Keepresso's code with
recorded provenance. Keepresso's helper keeps its own code until Stage E.

The UI never changes. `KeepressoCore` re-exports the shared modules and keeps
every public type name. The 42 files that import it compile with no edits.
Xcode targets consume `KeepressoCore` as a package product, so new package
targets arrive transitively and `project.yml` does not change.

## Invariants

- **I1. UI, helper and session code untouched.** Through Stage D, this command
  must print nothing:

  ```sh
  git diff upstream/main --stat -- Sources/Keepresso Sources/KeepressoWidget \
    Sources/keepresso-cli Sources/keepresso-helper Sources/keepresso-mcp \
    project.yml
  ```

  - In `Sources/KeepressoCore`, only the files listed as "moved" in
    SOURCE-INVENTORY.md may change, plus any new wrapper files.
  - `Tests/KeepressoCoreTests` may only change by moving a test to the shared
    module's tests, with an equivalent test left against the wrapper. Deleting
    an existing test is not allowed.
  - `Package.swift` may gain targets and add dependencies to `KeepressoCore`.
- **I2. Always green.** Every commit passes `swift build` and the full
  `swift test`. The Keepresso pass count never drops below the Stage 0 baseline.
- **I3. Behavior preserved.** A moved condition behaves exactly as before
  through its wrapper, including missing readings, empty rule sets, saved
  formats and raw values. Any deliberate difference needs a DECISIONS.md entry
  approved by jbrest.
- **I4. Provenance for seeded code.** Code in PowerControl and ServiceSupport
  seeded from Keepresso's helper, and code ported from the archive, is listed in
  SOURCE-INVENTORY.md with its source, revision and port type. The ported file
  has a one-line header comment naming its source.
- **I5. Rebase and check.** Rebase on `upstream/main` at least at each stage
  boundary. Resolve conflicts in moved files by applying gyorgysh's change to the
  shared code. For seeded helper code, run
  `git diff <recorded revision> upstream/main -- <file>` and port or note each
  change.
- **I6. Nothing leaves the machine without approval.** Pushing to `origin` (a
  public fork) and any contact with upstream each need jbrest's explicit
  approval.

## Stages

### Stage 0: archive and baseline

Done:
- Archive tag `archive/headless-in-keepresso-2026-11-02`.
- Branch `sh/foundation` from `upstream/main` `7ea73a6`.
- This documentation set.

Remaining:
1. Codex reviews the docs per CODEX-BRIEF.md. jbrest settles disagreements, and
   the docs are updated.
2. Capture the upstream baseline: `swift build`, the `swift test` pass count,
   toolchain, SDK and macOS. Record it in NOTES.md, and ask before starting the
   test run if it is long.

Exit: the review is settled, the baseline is recorded and the docs are committed.

### Stage A: move and adapt the rules and observations

One condition type per commit or small series, in this order (simplest first,
which sets the pattern):

1. Scaffolding:
   - empty `RuleModel`, `RuleEvaluation` and `SystemObservations` targets;
   - `KeepressoCore` depends on them and re-exports them;
   - `Observation`, `Verdict` and the three-state combine, with tests.
2. Power source:
   - snapshot to RuleModel and reader to SystemObservations;
   - matching to RuleEvaluation;
   - `PowerSourceTrigger` becomes a wrapper with its two-state adapter.
3. Time window: `TimeWindowRule` fields and the evaluator move; the trigger
   becomes a wrapper.
4. CPU load: reader to SystemObservations, state machine to RuleEvaluation, and
   the trigger becomes a wrapper.
5. Network throughput: same pattern as CPU load.
6. Process matching and process listing (`ProcessList`, `SharedPSSnapshot`).
7. New SH-only conditions:
   - SSH session reader that counts authenticated sessions only (F4), with
     fixtures for authenticated sessions, pre-auth connections and a listener
     only;
   - console session reader prototype, with validation results written up (O5).
8. Thermal and battery readers, if O8 adopts safety.

For every move:
- Write down how the old trigger treated a missing reading. Record it as that
  condition's row in the O11 table in DECISIONS.md, and make the adapter
  reproduce it.
- Saved shapes such as `RuleSet` and `TriggerRule` Codable stay in
  `KeepressoCore`, mapping to and from the shared values (T3).
- Labels, localization, factories and the `Trigger` protocol stay in
  `KeepressoCore`.

Exit:
- All Keepresso tests pass at or above the baseline count.
- The shared modules build with only their declared dependencies.
- The three-state tests pass.
- A read-only smoke run of each real reader on a Mac is recorded.

### Stage B: power mechanism and PowerControl

- **B1. Experiment** (needs jbrest for reboots and logouts). Compare an
  IOPMAssertion held by a root daemon against `pmset disablesleep`, in each of:
  - lid open with idle sleep due;
  - no console login after a reboot with FileVault unlocked;
  - lid closed with and without external power;
  - helper crash;
  - Keepresso's helper holding or restoring the same setting at the same time.
  
  Record the results and settle O1.
- **B2. PowerControl**, built for SH and seeded from Keepresso's helper code
  with provenance (I4). It covers the chosen mechanisms, owner union, the
  restore journal, verification and launch reconciliation ordering (F3).

Exit: fake-backend tests for several owners, exact prior values, failed
operations, retained restore debt and reconciliation ordering.

### Stage C: SH service

- ServiceSupport, built for SH and seeded from Keepresso's helper code and the
  archive with provenance: peer validation, admin authorization, handshake,
  structured errors and diagnostics.
- SleeplessContracts.
- SleeplessRuntime: port from the archived Headless files with the fixes listed
  in SOURCE-INVENTORY.md.
- The `sleepless-helper` executable.

Exit:
- The ported archived tests pass, plus a regression test for each listed defect.
- The helper builds.
- An XPC contract test runs against an in-process listener.

### Stage D: SH app and installed acceptance

- **D1.**
  - Settle O2: identifiers and signing team. `sh.gyorgy.*` belongs to the
    upstream maintainer and must not be used.
  - Write `SleeplessHollow.yml` and the app per PRODUCT.md.
- **D2.** Rewrite the test-state cleaner for SH's identity, and build the
  evidence-bundle tooling from VALIDATION.md.
- **D3.** Run the installed acceptance matrix with jbrest. This includes:
  - removal during a verified hold;
  - reboot with no console login;
  - update over a previous build;
  - running alongside Keepresso.

Exit: every row of the installed matrix passes with retained evidence.

### Stage E (separate approval): Keepresso's helper adopts PowerControl and ServiceSupport

Start this once upstream churn in the helper files has settled. Keepresso's XPC
protocol and service identity do not change.

Exit:
- All Keepresso tests pass.
- An installed Keepresso test covers wake schedules, closed-display hold and
  restore, fans and helper approval.
- The seeded duplicate code is deleted.

### Stage F (separate approval): upstream offer

1. Offer any fixes that apply to upstream code as separate small PRs first. F4
   (the SSH pre-auth match in the upstream preset) is the likely first one, if
   A2 confirms it.
2. Then open one issue linking a branch with Stage A (and E, if done), rebased
   on current `upstream/main`. It contains no SH code, no SH docs and no
   fork-only changes. Cover five points:
   - what moved;
   - the evidence that nothing visible changed (zero UI diff, equal or higher
     test count);
   - what gyorgysh gains;
   - that they never need to touch SH;
   - jbrest's commitment, including fixing Keepresso regressions caused by the
     reorganization for a stated period.

### Stage G (optional): Keepresso runtime breakup

Split `SessionController` and the rest of Keepresso's runtime by responsibility,
if gyorgysh wants it. This is the stage that touches UI wiring.

## Work allocation

- Codex: most implementation in Stages A to D, under these docs.
- Claude Code: reviews at the checkpoints listed in NOTES.md.
- jbrest:
  - product decisions;
  - authentication prompts;
  - physical and remote-session steps (reboots, logouts, lid);
  - approving each push.

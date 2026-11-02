# Sleepless Hollow: migration and staging plan

Date: 2 November 2026, revised the same day (decision P7). Status: Stage A settlement
accepted by jbrest after Codex and Claude Code review. Current stage: A (see [NOTES.md](../../NOTES.md)).

## Strategy

There are two tracks, chosen by how risky and how actively changed the code is.

**Rules and observations: move and adapt now.** These files have had no upstream
commits from 3 September through 2 November 2026. The process listing files are the only exception,
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
From 3 September through 2 November 2026, the helper files had 20 file touches
(`HelperEngine` 7, `HelperService` 9, `HelperRecovery` 4), across 13 distinct
commits. They run as root, and
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
  - Every baseline Keepresso test identity must remain and pass. Pure cases may
    be copied into shared tests. Deleting or renaming a baseline test requires
    jbrest's approval; unchanged tests continue to exercise the wrappers (S5).
  - `Package.swift` may gain targets and add dependencies to `KeepressoCore`.
- **I2. Always green.** Every commit passes `swift build` and the full
  `swift test` with HelperConnectionTests scheduled separately, as upstream
  does. Every Stage 0 test identity remains and passes, not just the total count.
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
- **I7. Review all upstream code touched.** See the next section.

## Exit checklist for every implementation step

- Every baseline test identity remains and passes, including separately scheduled
  HelperConnectionTests. Record command results and counts.
- Run `python3 tools/check-shared-imports.py`.
- Run the protected I1 diff and confirm it is empty.
- Save a short durable evidence summary under `docs/sleepless-hollow/evidence/`
  with commands, identity-check output and build results. Full logs stay out of
  the repository. Build output must include the exit result or success marker;
  a quiet empty log alone is not retained evidence.

## Reviewing touched upstream code

Every upstream file that is moved, wrapped or seeded from gets a correctness
review before or during its move. So does any upstream code read closely to
understand one of those files. The aim is to find real Keepresso bugs that can
be offered back as standalone fixes.

**Scope.**
- Stage A: every file listed as moved in SOURCE-INVENTORY.md.
- Stages B and C: every helper file listed as seeded.
- Any other upstream file whose behavior a move depends on.

**What to check.**
- Logic and boundary cases.
- Handling of missing, stale or malformed readings.
- Error paths that are swallowed or turned into defaults.
- Units and conversions.
- Time, calendar and DST handling.
- Concurrency and actor isolation.
- Resource leaks: processes, file handles, IOKit objects, assertions.
- Behavior that contradicts the code's own comments or docs.
- For helper code also: privilege boundaries, caller validation, failing closed,
  and restore on crash or update.

Style preferences and refactoring opportunities are not findings.

**Rules.**
1. **Do not fix in place.** A move preserves current behavior exactly (I3),
   including suspected bugs. Record the suspicion instead.
2. **Record every finding** in the "Upstream fix candidates" table in NOTES.md,
   with:
   - an ID (U1, U2 and so on);
   - file and line at a stated revision;
   - what is wrong and its effect on users;
   - severity (high, medium, low);
   - status (suspected, confirmed, rejected or submitted).
3. **Confirm with a test.** On a separate branch `upstream-fix/<short-name>`,
   created from `upstream/main` in a separate worktree, write a test that fails on upstream code. Then
   write the smallest fix that makes it pass without breaking the full suite. A
   finding with no failing test stays "suspected". A finding the test disproves
   is marked "rejected", with the reason.
4. **Keep fixes off `sh/foundation`.** They reach this branch only through
   upstream, by rebasing after gyorgysh merges them. If SH needs the corrected
   behavior sooner, SH-only code can implement it. Changing shared behavior that
   Keepresso uses needs a DECISIONS.md entry approved by jbrest.
5. **Submit selectively.** Only confirmed findings of medium severity or higher,
   or low-severity ones that are trivially safe, are proposed to jbrest for
   submission. Each fix:
   - is its own small PR, with its test;
   - follows the repo's CLAUDE.md and the conventions of recently merged PRs;
   - is submitted only with jbrest's approval (I6).
6. **Security-critical findings.** Stop at the review checkpoint rather than
   shipping a known security-critical defect merely to preserve parity.
7. **Mark the review done.** Record the review of each file in the "Reviewed"
   column of SOURCE-INVENTORY.md's "Done" table, even when nothing was found.

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

1. **A1: scaffolding:**
   - empty `RuleModel`, `RuleEvaluation` and `SystemObservations` targets;
   - `KeepressoCore` depends on them and re-exports them;
   - the observation envelope (`SignalObservation`), `Verdict` and the
     three-state combine, with tests;
   - a short plain-Python framework/product import check, with no rg dependency
     or forbidden-import build experiments (S3).
2. **A2: power source:**
   - snapshot to RuleModel and reader to SystemObservations;
   - matching to RuleEvaluation;
   - `PowerSourceTrigger` becomes a wrapper with its two-state adapter.
3. **A3: time window:** `TimeWindowRule` fields and the evaluator move; the trigger
   becomes a wrapper.
4. **A4: CPU load (including TTLCache):** reader to SystemObservations, state machine to RuleEvaluation, and
   the trigger becomes a wrapper.
5. **A5: network throughput:** same pattern as CPU load.
6. **A6: processes**, including process matching and listing (`ProcessList`, `SharedPSSnapshot`).
7. **A7: SSH and console session**, new SH-only conditions:
   - SSH session reader that counts authenticated sessions only (F4), with
     fixtures for authenticated sessions, pre-auth connections and a listener
     only;
   - console session reader prototype, with validation results written up (O5).
8. **A8: thermal reading**, only if O8 adopts it. Battery level already comes
   from the power snapshot.

For every move:
- Preserve the current query/threshold evaluation against retained data when a
  reading fails. Record reader/cache/state behavior, not only an unknown-to-Bool
  function (S2).
- Add one or two source-citing comment lines only for compatibility-only or
  mixed state; list that state in a short migration table. Purely operational
  state needs no classification comment (S4).
- Write down how the old trigger treated a missing reading. Record it as that
  condition's row in the O11 table in DECISIONS.md, and make the adapter
  reproduce it.
- Saved shapes such as `RuleSet` and `TriggerRule` Codable stay in
  `KeepressoCore`, mapping to and from the shared values (T3).
- Labels, localization, factories and the `Trigger` protocol stay in
  `KeepressoCore`.

Exit:
- Every baseline Keepresso test identity exists and passes (S5).
- The shared modules build with only their declared dependencies.
- The three-state tests pass.
- A read-only smoke run of each real reader on a Mac is recorded.

### Stage B: power mechanism and PowerControl

- **Before B1:** Claude Code and jbrest review the experiment, temporary test
  identity, installation, cleanup and recovery steps. Existing services remain
  untouched and global BTM state is not reset.
- **B1. Experiment** (needs jbrest for reboots and logouts). Compare an
  IOPMAssertion held by a root daemon against `pmset disablesleep`, in each of:
  - lid open with idle sleep due;
  - no console login after a reboot with FileVault unlocked;
  - lid closed with and without external power;
  - helper crash;
  - Keepresso's helper holding or restoring the same setting at the same time.
  
  Record the results and settle O1, including coordination between two daemons
  for the selected mechanism before claiming coexistence.
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
- Stage C design gates: removal timeout/disconnect recovery and crash-atomic
  behavior at every phase; F2 rollback bound to owner/token and policy revision.
- Stage C design gates: autosave revision/conflict handling, startup-failure
  evidence and bounded external calls. Settle these here, not in Stage A.

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

1. Offer confirmed upstream fix candidates (see "Reviewing touched upstream
   code") as separate small PRs first. These can go as soon as each is confirmed
   and jbrest approves; they don't need to wait for Stage F. U1 (the SSH preset
   pre-auth match) is the first to check, during Stage A step 7.
2. Then open one issue linking a branch with Stage A (and E, if done), rebased
   on current `upstream/main`. It contains no SH code, no SH docs and no
   fork-only changes. Cover five points:
   - what moved;
   - the evidence that nothing visible changed (zero UI diff, all baseline test
     identities preserved and passing, and consumer builds);
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

# Brief for Codex: review and handoff

Date: 2 November 2026. From: Claude Code, at jbrest's request.

## Context

jbrest has replaced the earlier approach. The in-Keepresso Headless mode and
your modular proposal drafts are archived, unchanged, at tag
`archive/headless-in-keepresso-2026-11-02`, together with the uncommitted
drafts, which were committed first as `53d8240`. New work is on branch
`sh/foundation`, created from `upstream/main` `7ea73a6`. Nothing has been
pushed.

Read [README.md](README.md) first, then the other docs in the order it lists.

## What changed from your proposal

The goals of your proposal carry over: shared modules, typed observations with
availability, pure evaluation, separate SH service identity, a removal
transaction, and evidence-based acceptance. These parts are different:

1. **Scope.** Only the modules SH needs are built now. `KeepressoContracts`,
   `KeepressoRuntime` and `ProductAdapters` are deferred to Stages E and G.
2. **Two tracks (decision P7).**
   - **Rules and observations move out of `KeepressoCore` one condition at a
     time.** Each Keepresso trigger becomes a wrapper with its own two-state
     adapter. Keepresso's existing tests must pass unchanged after every move,
     and the UI is never edited.
   - **The privileged helper code is not moved.** SH's PowerControl and
     ServiceSupport are built fresh, seeded from it with recorded provenance.
     Keepresso's helper adopts them only in Stage E.
   - An earlier version of this plan built everything alongside Keepresso. It
     was revised the same day, and DECISIONS.md P3 and P7 record the change.
3. **PowerControl is narrowed to keep-awake holds.** AWDL and KeyboardLock stay
   in Keepresso.
4. **No SharedSupport module** for now (T6).
5. **Contracts do not depend on RuleModel.** Products map shared types into
   their own versioned DTOs (T3).
6. **Boundaries are enforced by SwiftPM target dependencies** rather than
   `check_boundaries.py` (T2).
7. **The docs are consolidated** into `docs/sleepless-hollow/`. `PRODUCT.md` and
   `VALIDATION.md` are carried forward from your drafts with edits.

## What you are asked to do

1. Read all seven docs. Check their factual claims against the code at
   `upstream/main` and at the archive tag: file names, line hints, semantics
   described as Keepresso's, and the defects F1 to F6.
2. Write `docs/sleepless-hollow/CODEX-REVIEW.md` containing:
   - for each technical decision T1 to T10 and for P7's two-track split: agree,
     or disagree with your reason and an alternative;
   - whether the Stage A order and the per-condition adapter approach are
     workable, and anything in `KeepressoCore` that makes a clean wrapper hard
     (for example, cross-file private access, or triggers that read state in
     `tick`);
   - factual errors in any doc, with file and line evidence;
   - missing items: sources, tests, defects, risks or stages;
   - proposed changes to stage order or exit criteria;
   - anything in your archived drafts that should come back, and why.
3. Do not change the other docs or write code yet. jbrest settles the review,
   then the docs are updated (by you or Claude Code, as jbrest chooses), and
   Stage 0 closes.
4. After Stage 0 closes, you implement Stages A to D. Keep NOTES.md, the
   "Done" table in SOURCE-INVENTORY.md and the O11 table in DECISIONS.md
   current as you go.
5. Stop at each review checkpoint listed in NOTES.md, and tell jbrest that a
   Claude Code review is due before continuing.
6. Review every upstream file you move, wrap or seed from for correctness bugs,
   following "Reviewing touched upstream code" in MIGRATION-PLAN.md.
   - Never fix a suspected upstream bug inside a move. Preserve the behavior
     and record it in the "Upstream fix candidates" table in NOTES.md.
   - Confirm each one with a failing test on a separate `upstream-fix/` branch
     from `upstream/main`.
   - jbrest decides which fixes are offered upstream, as small standalone PRs
     submitted as a goodwill gesture before any reorganization offer.
   - Low-value findings are recorded but not proposed.
   - In your review of these docs, say whether this procedure is workable and
     what you would change.

## Phase 2: settling the review and closing Stage 0

Settled on 2 November 2026 by jbrest, after Claude Code reviewed
CODEX-REVIEW.md. The review is accepted except where it is limited below. Treat
these as settled. If you disagree with one, write it under "Open questions" in
NOTES.md and carry on with the rest. Do not act on the disagreement.

### Settlement

**S1. All factual corrections are accepted.** That covers:
- frontmost belongs to `AppTrigger`, not ProcessCondition;
- the stale "Stage E" for the adapter (ARCHITECTURE.md line 135);
- the ambiguous step references;
- the churn counts, with their window stated;
- TTLCache was omitted;
- the thermal and battery sources;
- the wording that readers hold no state;
- the app-shell line counts;
- revision-and-symbol citations for `HelperService`;
- the F1 to F6 re-characterizations.

**S2. The six-point adapter contract is adopted as written**, plus one
clarification. Today a rule edit takes effect immediately, against the most
recent retained data:
- an edited process query is matched against the retained process snapshot;
- a changed CPU or network threshold is evaluated against the retained average.

This is intended Keepresso behavior (see the comments at U `ProcessList.swift`
~L64 and U `NetworkThroughput.swift` ~L150), and it matches what users expect.
An adapter that "keeps the last verdict when unknown" would break it, and is not
allowed.

**S3. Scope split.** Only the items that block Stage A are settled now.
- **Settle now (Stage 0):**
  - the adapter contract (S2);
  - TTLCache ownership (S6);
  - the doc corrections (S1);
  - the state comment rule (S4);
  - test parity by test identity (S5).
- **Record now, settle in the stage named:**
  - Stage C:
    - removal prepare timeout and disconnect recovery (review risk 1);
    - crash-atomic removal at every phase (risk 2);
    - the F2 rollback design with an owner-bound token and revision check;
    - autosave revision and conflict handling (risk 6);
    - startup-failure diagnostics and bounded external calls (risk 5).
  - Stage B: coordination between two daemons for the chosen mechanism
    (risk 4).
  
  Write each one into the relevant stage of MIGRATION-PLAN.md as a gate for
  that stage, one or two lines each. Do not design them now.
- **Adopt as written:**
  - a Claude Code and jbrest review checkpoint *before* B1. Test identity,
    install and cleanup steps are approved before the experiment runs; leave
    the existing service untouched and don't reset global BTM state.
  - separate git worktrees for `upstream-fix/` branches;
  - stop at a checkpoint rather than ship a known security-critical defect for
    parity's sake;
  - "unsupported" rather than a broad heuristic if authenticated SSH cannot be
    detected reliably.
- **Keep small:** the framework-import check is a short plain-Python or `grep`
  test. It fails if a shared module imports AppKit, SwiftUI, WidgetKit or
  another product module.
  - It must not depend on `rg`, which is not installed here.
  - No forbidden-import build experiments.
  - SwiftPM target dependencies remain the main boundary enforcement.

**S4. State comments (jbrest's rule).** Add a state comment only where some or
all of a piece of state would become unnecessary if an improved Keepresso
behavior were adopted later, for example:
- retaining a stale process snapshot after a failed listing;
- re-evaluating a retained average when a reading fails.

The comment:
- is one or two lines, one per state structure;
- says which part is needed only for current Keepresso behavior, and cites the
  source.

Purely operational state (counters for rate calculations, smoothing averages,
TTL caches, refresh flags) gets no classification comment, only the normal
comments the repo's style calls for. Each condition's migration notes list the
same compatibility-only and mixed state in a short table. That table becomes the
scope of any later Keepresso improvement.

**S5. Parity by test identity.**
- Capture the list of Keepresso test names at the baseline (`swift test list`
  or equivalent).
- After every move, every baseline test must still exist and pass. A total
  count is not enough.
- Copying a pure-logic case into a shared module's tests is fine. Deleting or
  renaming a baseline test needs jbrest's approval.

**S6. TTLCache** moves to SystemObservations in step A4 (CPU), the first move
that needs it. `KeepressoCore` keeps the name available to its other users,
including `Bluetooth`, `Diagnostics` and the app's `ThermalBackends`, through a
re-export or a type alias. Those users are not edited. Move its existing tests
the same way as the others (S5).

**S7. Stable step IDs.** Stage A steps are:
- A1: scaffolding.
- A2: power source.
- A3: time window.
- A4: CPU load, including TTLCache.
- A5: network throughput.
- A6: processes, including shared process acquisition.
- A7: SSH and console session.
- A8: thermal reading, only if O8 adopts it.

Replace every older "A2" or "A3" reference in the docs with these IDs.

**S8. Possible Keepresso improvements are not bugs.** Add a section to NOTES.md
called "Possible Keepresso improvements (not bugs)", separate from the upstream
fix candidates. Its first entry: Keepresso relies on retained process and
throughput data indefinitely when readings keep failing, without telling the
user the data is stale. A later improvement could limit how stale data may get
and show it in the UI. Nothing in this refactor changes it. It could be offered
to gyorgysh only if they want it.

### Tasks, in order

Each task is its own commit. Show jbrest a short plan before task 1, per
`.clinerules`.

1. **Apply the doc amendments.** Apply S1 to S8 to ARCHITECTURE, MIGRATION-PLAN,
   SOURCE-INVENTORY, DECISIONS (record S2 to S8 as decisions P8 onward), VALIDATION
   and NOTES. Keep the edits tight: correct and add only what the settlement
   says, and don't restructure or expand the docs otherwise. CODEX-REVIEW.md is
   already committed; leave it unchanged as the record.
2. **Capture the upstream baseline** on `sh/foundation`. Ask jbrest before
   starting a long run.
   - Record in NOTES.md: `swift build`, the full `swift test` with
     `HelperConnectionTests` scheduled separately as upstream does, the pass
     count, toolchain, SDK and macOS.
   - Save the test-name list as
     `docs/sleepless-hollow/baseline/tests-7ea73a6.txt`.
   - Build the app and widget consumers with `xcodegen` and `xcodebuild` if
     jbrest approves the time. Otherwise record that they were not built.
3. **Stage A1: scaffolding.**
   - Empty `RuleModel`, `RuleEvaluation` and `SystemObservations` targets.
   - `KeepressoCore` depends on them and re-exports them.
   - `Observation`, `Verdict` and three-state combine, with empty `any` and empty
     `all` both unsatisfied, matching `TriggerEngine`. Include tests.
   - The import check from S3.
   - Exit:
     - every baseline test still exists and passes;
     - `swift build` succeeds for all package products;
     - the I1 diff is empty.
4. **Stop.** Update NOTES.md and tell jbrest that the Claude Code checkpoint
   before A2 (power source) is due. Do not start A2.

## Claude Code review of A1 (2 November 2026)

A1 is accepted. The `SignalObservation` rename is right. Before A2:

1. **Re-run the app build.** `/tmp/sh-a1-app-build.log` is empty (0 bytes), so
   there is no evidence that the app target, with its 28 `@Observable` files,
   builds after the re-export was added. Re-run the unsigned Debug app build and
   keep the result.
2. **Keep evidence durable.** `/tmp` is cleared on reboot. For each step, save a
   short summary to `docs/sleepless-hollow/evidence/<step>.md`: the commands,
   pass counts, the identity-check output and the build result. Full logs stay
   out of the repo.
3. **Add the import check to every step's exit checklist** in
   MIGRATION-PLAN.md, alongside the identity check and the I1 diff.
4. **Remove the `RuleModel`, `RuleEvaluation` and `SystemObservations` library
   products** from `Package.swift`. Targets in the same package don't need them,
   so they only add public surface. Add products back if something outside the
   package ever needs them.

For the A2 checkpoint, with no separate commit needed before then:

5. **Rename the shared `Verdict`** to `RuleVerdict`. Keepresso already has three
   nested `Verdict` types (`FanDryRun`, `AutomationLease`,
   `AutomationWakeControl`). They don't clash today, but four meanings of one
   name invite mistakes.
6. **Naming rule, to add to ARCHITECTURE.md:**
   - A shared type never reuses the name of an Apple module or of a type that
     stays in `KeepressoCore`.
   - A type that moves exists in exactly one place: reachable through the
     re-export, or through an alias, never both.
   - Never rename Keepresso's own types or members to make room. Shared code
     adapts to Keepresso's names, not the other way round.

## Claude Code review of A2 (2 November 2026)

A2 is accepted as the pattern for later conditions. Behavior is preserved
exactly; the compatibility test target comparing every provider and charging
combination with the original predicates is a good model for A3 onward.

Before or alongside A3:

1. **Keep upstream doc comments on retained Keepresso API.** A2 deleted
   gyorgysh's comments on `PowerSourceMonitoring.current` ("Reading is cheap;
   callers may poll it.") and `IOKitPowerSourceMonitor` (the threading note).
   Restore them, adjusted only where the move made them untrue. Where a
   Keepresso type or member stays, its upstream comments stay too. This keeps
   the diff he will review small and keeps information he wrote.
2. **New checkpoint after A4.** Power source has no state, so the hard pattern
   questions arrive with CPU load: smoothing state, `TTLCache`, `@testable`
   access to `step`, and the first S4 comments. Stop after A4 for a Claude Code
   review before A5. NOTES.md lists it.

Noted for Stage C, no action now: `PowerSourceObserving` and the reader are not
`Sendable`. That's fine for Keepresso's main-actor use. The SH service loop
should decide its isolation before relying on them across threads.

## Claude Code review of A3 and A4 (2 November 2026)

Both accepted. I compared each against upstream line by line: the time window,
the counter delta (including when `previous` updates on failure), the TTL
cache, smoothing, failed-read reevaluation, malformed thresholds and the
constants all behave identically. Proceed to A5 (network throughput) with the
CPU pattern. Small items to fold into A5:

1. **S4 comment placement.** The comment on `CPULoadTrigger.state` calls it
   "Mixed state". Under jbrest's rule, none of that state would become
   unnecessary with an improved Keepresso: the average and the hysteresis flag
   are fully operational. The compatibility-only part is a behavior, the
   failed-read `reevaluate` branch in `step`. Move the comment to that branch
   and phrase it as compatibility behavior, citing the source. Use the same
   placement for network throughput. Reserve S4 state comments for state that
   really would go away, such as the retained process snapshot in A6.
2. **Carry gyorgysh's comments into moved code too.** `MachCPUUsageReader`
   lost his explanation of why the cache is lazy and holds `self` unowned, and
   the line describing the Mach tick counters. Restore them in the shared file.
3. **U2 analysis (corrected after Codex's reply).** Keep U2 suspected, and
   record the arithmetic risk separately from its real-world likelihood, as
   Codex proposed. The arithmetic risk is real: a lower `busy` with a higher
   `total` needs only enough idle growth to offset the drop. Likelihood:
   - A single 32-bit lane wrap lowers `busy` by about 4.3 billion ticks.
     Offsetting that needs equal idle growth within one sample interval, which
     takes weeks at typical tick rates, so continuous polling should not hit it.
   - Unverified: whether `busy` can fall without a wrap, for example if the
     aggregate counters change when processors go offline or sleep.
   - Long gaps between samples on one reader instance remain a plausible path.
   
   The same check applies to the network counters in A5.
4. **New checkpoint after A6.** Processes bring the first real
   compatibility-only state (the retained snapshot after a failed listing) and
   acquisition shared with agent monitoring. Stop after A6 for a Claude Code
   review before A7. NOTES.md lists it.

## Working rules

The repo's `.clinerules` and `CLAUDE.md` apply:
- Before multi-step work, state a short plan and wait for approval.
- Never read a whole file over 300 lines; search, then read ranges.
- One goal per task.
- Stop and explain after two failed approaches.
- Ask before long-running or background commands.
- Keep NOTES.md current after each milestone.
- Do not reopen settled items (the "Decided" section of DECISIONS.md and the
  Phase 2 settlement). Record disagreement in NOTES.md instead.
- Never use em dashes in prose, comments, commit messages or UI copy.
- Keep `ENABLE_APP_SANDBOX: false`.
- Never commit `Keepresso.xcodeproj`.

Commits should be tidy because the fork is public. Do not push without jbrest's
approval, and never contact upstream.

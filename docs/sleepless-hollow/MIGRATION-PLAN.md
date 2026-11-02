# Sleepless Hollow: migration and staging plan

Date: 2 November 2026. Status: proposed, pending Codex review. Current stage:
0 (see [NOTES.md](../../NOTES.md)).

## Strategy: build alongside, adopt later

The shared modules are new targets built next to Keepresso, seeded from
Keepresso's code. Keepresso is not modified while SH is built. Only after SH
works (Stage D) does Stage E switch Keepresso onto the shared modules through
an adapter layer, then delete the duplicated code.

Why:
- Every commit builds and Keepresso keeps working, so each step can be
  reviewed on its own.
- The shared modules can be designed properly rather than shaped by file moves.
- Rebasing on upstream stays cheap, because Keepresso's files don't conflict.
- If Stage E never happens, SH is unaffected.

Cost: until Stage E, some logic exists twice. The provenance check (I4) is how
upstream changes to the copied logic get noticed.

## Invariants (Stages 0 to D)

- **I1. Keepresso untouched.** This command must print nothing:

  ```sh
  git diff upstream/main --stat -- Sources/Keepresso Sources/KeepressoCore \
    Sources/KeepressoWidget Sources/keepresso-cli Sources/keepresso-helper \
    Sources/keepresso-mcp Tests/KeepressoCoreTests project.yml
  ```

  `Package.swift` may only gain new products and targets.
- **I2. Always green.** Every commit passes `swift build` and `swift test` for
  all targets.
- **I3. Provenance.** Every ported unit is listed in SOURCE-INVENTORY.md with:
  - its source file and revision (an upstream commit or the archive tag);
  - whether it was ported verbatim, adapted or redesigned.

  The ported file carries a one-line header comment naming its source.
- **I4. Rebase and check.** Rebase on `upstream/main` at least at each stage
  boundary. Then, for every Keepresso file listed as a source, run
  `git diff <recorded revision> upstream/main -- <file>`. Each change is either
  ported or noted as not applicable, and the recorded revision is updated.
- **I5. Nothing leaves the machine without approval.** Pushing to `origin` (a
  public fork) and any contact with upstream both need jbrest's explicit
  approval each time.

## Stages

### Stage 0: archive and baseline

Done:
- Archive tag `archive/headless-in-keepresso-2026-11-02`.
- Branch `sh/foundation` from `upstream/main` `7ea73a6`.
- This documentation set.

Remaining:
1. Codex reviews the docs per CODEX-BRIEF.md. jbrest settles disagreements, and
   the docs are updated.
2. Capture the upstream baseline on `sh/foundation`: `swift build`, `swift test`
   pass count, toolchain, SDK and macOS version. Record it in NOTES.md. Ask
   before starting the test run if it is long.

Exit: the review is settled, the baseline is recorded and the docs are committed.

### Stage A: shared foundations

Ordered by dependency. Each item is its own commit or small series.

- **A1. RuleModel and RuleEvaluation.**
  - Port the condition semantics from Keepresso's triggers. Port Keepresso's
    relevant tests for power source, process matching, time windows, and CPU
    and throughput smoothing, and make them pass against the new code.
  - Add three-state tests: unavailable samples, and Kleene combine for any and
    all with mixed unknowns.
  - Exit: both targets build with Foundation only; the tests pass.
- **A2. SystemObservations.**
  - Readers behind protocols, with fakes for tests.
  - SSH classifier with fixtures for authenticated sessions, pre-auth
    connections and a listener only.
  - A console-session reader prototype, with its validation results written up.
  - Exit: the tests pass; a read-only smoke run of each real reader on a Mac is
    recorded; the console-session method is documented (O5).
- **A3. ServiceSupport.**
  - Port peer validation, admin authorization and the probe fixture from the
    archive, with their tests.
  - Add the handshake, structured error and diagnostics log types.
  - Exit: the tests pass, including the ad-hoc cdhash pin and team requirement
    cases.

### Stage B: power mechanism and PowerControl

- **B1. Experiment** (needs jbrest for reboots and logouts). Compare an
  IOPMAssertion held by a root daemon against `pmset disablesleep`, in each of:
  - lid open with idle sleep due;
  - no console login after a reboot with FileVault unlocked;
  - lid closed with and without external power;
  - helper crash.
  
  Record the results and settle O1.
- **B2. PowerControl.** Implement the chosen mechanisms, owner union, the
  restore journal and verification.
  - Exit: fake-backend tests cover several owners, exact prior values, failed
    operations, retained restore debt and launch reconciliation ordering.

### Stage C: SH service

- SleeplessContracts.
- SleeplessRuntime: port from the archived Headless files with the fixes listed
  in SOURCE-INVENTORY.md.
- `sleepless-helper` executable.

Exit:
- The archived Headless tests, adapted and ported, pass, plus tests for each
  listed defect.
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

### Stage E (later, separate approval): Keepresso adoption layer

Covered in the last section of ARCHITECTURE.md:
- re-exports and type aliases;
- the two-state adapter;
- triggers as thin wrappers;
- equivalence tests;
- deletion of the duplicated code.

Exit: Keepresso's full test suite passes at the Stage 0 baseline count or
higher. The app-shell and widget sources have no diff, and all 15 localizations
are unchanged.

### Stage F (later, separate approval): upstream offer

1. Offer any archived fixes that apply to upstream code as separate small PRs
   first. Which ones apply is not yet checked.
2. Then open one issue linking a branch containing Stages A and E only, rebased
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

Offered only after upstream PR #31 ("Make manual and automatic session activity
clearer", which reworks `SessionController`) is resolved, and only if gyorgysh
wants it. It splits `SessionController` and the rest of Keepresso's runtime by
responsibility. This is the stage that touches UI wiring.

## Work allocation

- Codex: most implementation in Stages A to D, under these docs.
- Claude Code: reviews at stage boundaries.
- jbrest:
  - product decisions;
  - authentication prompts;
  - physical and remote-session steps (reboots, logouts, lid);
  - approving each push.

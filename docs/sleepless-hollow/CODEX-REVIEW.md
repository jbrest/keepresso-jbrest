# Codex review of the Sleepless Hollow foundation plan

Date: 2 November 2026. Reviewed branch: `sh/foundation`, commit `42e5f60`.
Sources checked: upstream `7ea73a6` (U) and archive `53d8240` (A).

This is a source/document review, not implementation or installed acceptance.
Only this review file is added. No other planning document, runtime source,
policy or service registration was changed. No test suite or new regression
experiment was run. References below identify revision, path and source lines;
archive paths can be read with `git show 53d8240:<path>`.

## Overall assessment

I support the new direction and P7's two tracks. It gives Keepresso real shared
rule consumers early, avoids a wholesale runtime rewrite, and isolates the more
sensitive helper migration. Starting from upstream and retaining the old branch
as evidence is materially easier to reason about than incrementally undoing the
in-Keepresso Headless UI.

I would settle the compatibility details below before Stage A implementation.
The most important change is to describe a compatibility adapter as preserving
reader/cache/state behavior, not merely mapping a three-state enum to Bool.
The remaining disagreements are bounded and do not require a different project.

## Technical decisions

| Decision | View | Conditions or proposed adjustment |
| --- | --- | --- |
| T1: two tracks | Agree | Move and wrap the stable rule/observation code; seed narrowly scoped SH helper code separately. Track seeded duplication explicitly and reconcile it on rebases. The churn numbers need correction, but the rationale holds. |
| T2: SwiftPM boundaries | Agree, with qualification | Real targets and actual consumer builds replace the old feasibility script as primary evidence. Declared dependencies do not by themselves enforce the documented ban on importing SDK frameworks such as AppKit, or prevent someone declaring a forbidden dependency. Add dependency-allowlist and framework-import checks, plus representative forbidden-import build checks. |
| T3: product-owned DTOs | Agree | Keep the existing Keepresso Codable types and raw values as product-owned wrappers with explicit conversions. A typealias to a shared Codable type is not sufficient format isolation. Shared runtime values need not themselves be Codable. |
| T4: three-state evaluation | Agree | Define empty any and empty all explicitly as unsatisfied for this product, matching existing TriggerEngine. Preserve raw availability independently of retained legacy state. O10 must be settled before SH can enforce an unknown aggregate. |
| T5: narrow PowerControl | Agree | Keep only keep-awake mechanisms and their recovery. Do not import the full HelperEngine or its fan/AWDL/keyboard dependencies. O1 remains an empirical choice, not an assertion that all mechanisms are equivalent. |
| T6: no SharedSupport | Agree | TTLCache is a concrete missing dependency. Place its neutral implementation in SystemObservations with a Keepresso compatibility wrapper, or redesign reader-local caching explicitly. No grab-bag is needed. |
| T7: SH protocol 1 | Agree | Independent endpoint, identity and schema. The current upstream helper is protocol 12; protocol 16 belongs to the archive. Do not inherit either numbering sequence. |
| T8: separate XcodeGen spec | Agree | Verify that the generated SH project does not overwrite Keepresso.xcodeproj or mutate existing entitlements. Build existing app, helper, CLI, MCP and widget consumers after each extraction. |
| T9: thin SH app | Agree | Contracts should contain the DTOs, field constraints and capability descriptions needed for editing. The helper remains authoritative for validation, authorization and evaluation. PRODUCT's local input validation must not require importing SleeplessRuntime. |
| T10: first evaluation before reconciliation | Agree with the objective; incomplete as a complete handover guarantee | Reconcile an inherited journal against validated current demand before blindly restoring. Specify invalid/missing policy, unknown samples, safety pause and failed readback. This ordering alone cannot prevent an assertion disappearing when its owner exits, or a service crash during handover. Test actual mechanism-specific continuity. |

**P7 specifically:** agree. There is no need to adopt PowerControl in Keepresso
before SH has established its own mechanism and recovery behavior. Conversely,
building shared readers with Keepresso wrappers now gives valuable compatibility
feedback. Keep the approved scope independent of PR #31, as requested. Its
SessionController redesign is not a reason to block this work.

## Stage A feasibility and the adapter contract

Power, time, CPU, throughput, then processes is a workable order. The power
checkpoint is a good place to review source layout, formatting/DTO ownership,
export strategy and missing-reading behavior before repeating the pattern.

Required changes to the implementation contract:

1. **Preserve observation history, not just the last Bool.**
   `PSProcessLister.current` returns stale cached commands immediately and
   refreshes asynchronously; failed fetches retain those commands (U,
   `ProcessList.swift:54-84`). A current query is still matched against that
   retained snapshot (`Trigger.swift:212-223`). Returning the previous verdict
   on unknown is not equivalent if the query changed. Preserve the cached
   snapshot, refresh timing and last-success metadata in the legacy adapter.
   Distinguish last successful sample time from last attempted fetch time.
2. **CPU/network nil behavior includes reevaluation.**
   Their smoothing steps do not change the average for nil samples, but still
   validate the threshold and calculate a verdict from the retained average
   (U, `CPULoad.swift:127-153`, `NetworkThroughput.swift:152-174`). A threshold
   change during a failed read can change the old result. Preserve a shared
   accumulation primitive and expose explicit legacy reevaluation rather than
   blindly freezing state whenever Observation is unavailable. SH can report
   unknown and retain accumulator state without changing Keepresso semantics.
3. **Keep old internal seams callable.**
   Tests call `CPULoadTrigger.step`, `NetworkThroughputTrigger.step` and
   `ProcessTrigger.matches` using `@testable import KeepressoCore`. Keep these
   forwarding functions and nested SmoothingState APIs. Moving an internal
   initializer to another module makes it inaccessible to those tests unless
   the compatibility wrapper forwards it or the shared seam becomes accessible.
   Reader injection initializers are at U `CPULoad.swift:42` and
   `NetworkThroughput.swift:47`.
4. **Keep time configuration owned by the product.**
   U `TimeWindow.swift:5-45` combines stored Codable fields, labels and internal
   formatting helpers. Preserve TimeWindowRule as a Keepresso value with explicit
   conversion to TimeWindowCondition; do not alias it to the shared saved shape.
   Preserve full-day equal endpoints as well as overnight/day-boundary behavior
   (`TimeWindow.swift:77-97`).
5. **Do not alter tick/read cadence.**
   CPU and network advance in tick, not isSatisfied. TriggerEngine advances all
   triggers before short-circuit evaluation (U `Trigger.swift:325-354`). Keep
   this behavior. Raw delta readers also have state and a 0.5 s cache; “no
   decision state” must not be interpreted as making those readers stateless.
6. **Power availability must not alter existing combinations.**
   Unknown provider maps to false for AC/battery, while charging directly reads
   isCharging (U `Trigger.swift:88-94`). The unavailable blob fallback explicitly
   sets charging false (U `PowerSource.swift:57-59`). Preserve those distinctions
   even in injected snapshots with unknown provider and charging true.

There is no demonstrated cross-file private-access blocker requiring broad UI
changes. The practical obstacles are internal visibility, nested public names,
product-owned Codable/presentation types, reader caches and shared process
acquisition. Each needs an explicit forwarding/conversion design.

The `_exported import` convenience should be narrowly documented and validated
with consumer builds. It is not a substitute for testing every old public and
@testable entry point. Prefer targeted aliases/wrappers where full re-export
would leak new types or create ambiguous names.

## Required state classification and code comments

Addition requested by jbrest after discussing this review: Claude Code should
review this requirement and incorporate it into the implementation rules when
Stage 0 is settled.

For every mutable state field or cohesive state structure moved, introduced or
retained in a compatibility wrapper, add a concise code comment explaining its
purpose and classifying it as one of:

- **Operational:** needed for acquisition, correct evaluation, performance,
  diagnostics or recovery regardless of legacy Boolean behavior. Examples:
  previous counters for rate calculations, smoothing averages, hysteresis,
  process caches, last-success timestamps and refresh coordination.
- **Compatibility-only:** retained solely to reproduce existing Keepresso
  behavior. Identify the old behavior and its source reference, keep it in the
  Keepresso adapter, and state what approved change would allow its removal.
- **Mixed:** useful underlying state also supports a legacy policy. Identify
  the useful portion and the compatibility-specific use separately. Do not
  imply the whole field can disappear when the legacy policy is retired.

Comments should also identify the state owner and meaningful reset/invalidation
conditions. One comment on a small cohesive state structure is sufficient when
it clearly covers its fields. Record the classification in the per-condition
migration notes and review it at the power-source pattern checkpoint and later
condition reviews. Do not classify a field as compatibility-only merely because
its first consumer happens to be the Keepresso wrapper.

Shared modules should hold the useful observation/evaluation state. The
Keepresso adapter should hold decisions and extra bookkeeping required only for
legacy behavior. SH should not need to allocate or maintain legacy-only fields.
Where a cache is useful to both products but their failure policies differ,
share the cached observations/freshness machinery and keep the policies separate.

A later, separately approved Keepresso improvement could expose unknown readings
and freshness to users, define explicit unavailable-reading policy, and remove
compatibility-only logic. That is not part of this behavior-preserving refactor.
It would not eliminate counters, smoothing, caches or recovery state still
required for their operational purpose. Tests must distinguish those functions
from the legacy fallback behavior they currently support.

## Factual errors, stale references and missing source entries

| Item | Evidence | Correction |
| --- | --- | --- |
| ProcessCondition has a frontmost mode | U `Trigger.swift:147-161` has AppTrigger.match; `ProcessTrigger:198-223` only has a substring query | Frontmost belongs to app/workspace rules. Do not add a GUI dependency to ProcessCondition. |
| Keepresso's two-state adapter is Stage E | ARCHITECTURE, RuleEvaluation section; P7 and Stage A say the opposite | Change this stale reference to Stage A. |
| A2 references for SSH and console work | Stage A lists power as step 2 and new session readers as step 7 | Replace ambiguous A2 references in inventory/decisions with Stage A step 7, or introduce stable substage IDs. |
| Helper churn is 6 + 8 + 4, described as 18 changes | `git log upstream/main --since=2026-09-03T00:00:00Z --format=%H -- <file>` gives HelperEngine 7, HelperService 9, HelperRecovery 4 | State the window and whether counting file touches or distinct commits: 20 file touches, 13 distinct commits across the three files. Rule files are unchanged in that window except one touch each for ProcessList and SharedPSSnapshot. |
| TTLCache omitted from moved inventory | U `CPULoad.swift:32`, `NetworkThroughput.swift:37` refer to Core's TTLCache | Inventory the cache and its tests, and resolve its ownership before those readers move. |
| Thermal.swift/BatteryLowPower.swift described as safety reading sources | U Thermal.swift primarily defines values/protocols; real pressure reader is `Sources/Keepresso/ThermalBackends.swift:9`; BatteryLowPower.swift controls pmset low-power modes | For simple thermal pressure seed a new SH reader or preserve a separate provenance entry. Battery level is already supplied by PowerSourceSnapshot. Do not move low-power mode control as battery-level sampling. |
| Power snapshot no-decision-state wording | U CPU reader stores previous ticks and TTLCache; throughput stores previous bytes/time | Permit acquisition/delta/cache state while keeping threshold/grace decisions in RuleEvaluation. |
| “42 files import KeepressoCore” | Current `rg -l '^import KeepressoCore' Sources --glob '*.swift'` returns 42 | Verified as a count of current direct importers, not proof that every consumer compiles after extraction. |
| App shell line totals | U-to-A numstat under Sources/Keepresso: 30 files, 2,955 added, 183 removed | Say 2,955 added lines, not total changed lines (3,138). This is historical size only. |

The current upstream has 94 Core Swift files. Do not carry the archived 101-file
inventory count into the fresh baseline. The listed archive file lengths,
67-line SSH harness and 48 total fixture lines (36 Swift + 12 plist) agree with
the archive. HelperService line hints differ between U and A, so cite revision
and symbol rather than relying on approximate line 144.

## Archive defects F1 to F6

- **F1: confirmed source-level authorization gap.** A
  `HeadlessSupervisor.swift:145-178` only checks administrator identity inside
  the enabled-policy branch. The listener admits the signed console account
  without requiring it to be admin (`HelperPeerPolicy.swift:18-20`). That account
  can prepare removal of a disabled/absent policy and block later writes. Require
  admin on the mutation endpoint, not only on connection or enabled-policy path.
- **F2: source behavior confirmed; rollback semantics need a decision.** A
  `HeadlessSupervisor.swift:181-186` clears removal flags without restoring the
  earlier policy. Restoring on a failed unregister is reasonable, but specify
  an authorized, owner-bound transaction with a token/generation and policy
  revision check. Do not re-enable after successful unregister or overwrite a
  newer edit. Cancel must not become a broadly callable “enable old policy” verb.
- **F3: ordering confirmed; live impact not established.** A
  `keepresso-helper/main.swift:502` calls restoreAtLaunch before supervisor.start
  at 519. The source permits restore/reacquire; this is not yet an installed
  proof of a sleep event. Preserve the original journal baseline when adopting
  an inherited active hold. Cover invalid policy and unknown initial demand.
- **F4: authenticated-session proof is missing.** A
  `HeadlessDiagnostics.swift:152-169` classifies name matches as candidates,
  and sampler line 70 treats candidates as true. It does not authenticate them.
  Rejecting pre-auth connections is a sound requirement; real macOS fixture
  evidence is needed before claiming exactly which pre-auth names match. U1
  should stay suspected, not be elevated to a proven upstream bug.
- **F5: acceptance gap, not a demonstrated code defect.** A already calls
  engine.releaseSleepHoldForRemoval and stops on failure (supervisor 160-175).
  A `HelperEngine.swift:488-501` checks actual readback and preserves restore
  debt on mismatch. Retain this mechanism and prove it installed; do not imply
  verified release is missing from the archive. Prior value true is a legitimate
  restored baseline and is not evidence of a failed release.
- **F6: missing optional product feature, not yet a confirmed bug.** O8 is open.
  If adopted, define precedence, hysteresis, unavailable safety data and UI status,
  then require tests. Do not silently broaden PowerControl into fan control.

The inventory's statement that the peer-path/getgrouplist defects are fork-only
is supported: U `HelperService.swift:204-214` resolves the explicitly named
Keepresso executable; A introduced generic bundle-name resolution and its fix.
U contains no getgrouplist policy authorization. The SH generic executable-path
code should keep the archive's corrected direct plist read and regression test.

## Removal, startup and experimental-test risks to add

1. Removal preparation needs an owner-bound timeout/disconnect recovery path.
   New idle policy refuses exit during removal. Without recovery, a client dying
   after prepare can leave the service permanently prepared and policy disabled.
   Explicitly decide automatic rollback versus an admin recovery action.
2. Persisted disable plus in-memory rollback state is not crash-atomic. Test a
   daemon crash and client crash at every removal phase; define what policy is
   accepted after restart and how unfinished removal is reported.
3. Settle temporary test identities and approved cleanup/rollback before B1.
   B1 is an installed privileged daemon experiment, even though production app
   identity is otherwise deferred to D1. Add a Claude/user review checkpoint
   before the experiment, not only after its results. Keep the existing service
   untouched and do not reset global BTM state.
4. Confirm O1's mechanism choice before claiming two-product compatibility.
   Independent assertions combine differently from a shared persistent pmset
   setting. First-evaluation ordering alone does not coordinate two daemons.
5. Add startup failure evidence before an XPC listener or policy loop is ready.
   A helper that exits cannot answer a diagnostics request. Bound every external
   process and BTM inspection with timeouts; collectors must not hang acceptance.
6. Policy autosave needs revision/conflict handling across two admin windows or
   users. Match readback to the submitted revision/request, not any newest file.
   In-flight writes, failed validation and removal must serialize consistently.

## Stage order, tests and upstream-fix procedure

Keep the proposed order, with these changes to gates:

- Stage 0: settle this review, fill missing inventory/contract decisions and
  capture a fresh upstream baseline. The archive's 1,223 tests are not that
  baseline. No baseline run was performed in this review.
- A1: scaffold real targets, three-state tests and product DTO conversions;
  establish forbidden dependency/import checks and existing consumer builds.
- A2: review power wrappers and tests with Claude before repeating the pattern.
  Include unknown provider, charging, malformed values and old Codable fixtures.
- A3-A6: preserve legacy tests and add sequence tests for changed parameters,
  missing samples, first sample, stale caches and repeated UI reads. Inventory
  process/agent acquisition sharing, not only process matching.
- A7: keep SSH/console read-only experiments bounded. If authenticated SSH cannot
  be detected reliably, report unknown/unsupported rather than ship a broad
  sshd-process heuristic as an authenticated-session condition.
- Before B1: approve experiment design, identity and recovery. B2 must carry
  F3/journal tests and independent-owner tests for the selected mechanism.
- C: exercise authorization, removal transaction crash points/timeouts and
  protocol/readback conflicts before adding the configuration UI.
- D: first settle authentication/autosave interaction, then review the installed
  scripts before execution. Retain actual before/after evidence per case.

Do not gate parity only on a total test count. Keep an inventory of existing
Keepresso test identities and their execution; shared/SH tests can otherwise
increase the total while original coverage disappears. Run the full suite using
upstream's separate XPC scheduling where appropriate, and build all old consumers
with their actual transitive SwiftPM dependencies. Zero UI source diff is useful
but is not proof of unchanged UI behavior or resource lookup.

I7's review and separate upstream-fix branches are workable. Use isolated
worktrees so confirming a bug cannot accidentally move the active foundation
checkout or contaminate a behavior-preserving commit. Keep source-only evidence
separate from a failing-test confirmation. Some root/lifecycle faults require an
instrumented installed reproduction; lack of a unit test must not silently
reject a potentially serious finding. Prefer a minimal automatic regression
where feasible, document external prerequisites otherwise, and get approval
before any live mutation. Re-review when upstream changes invalidate a finding.
A known security-critical defect must not be shipped merely to satisfy parity;
record it, stop at the checkpoint and obtain a decision before adopting the code.

Do not make SH depend indefinitely on upstream accepting a fix. The existing
approved-decision exception for shared behavior is the correct escape route,
with a separate explicit fix commit and parity expectations updated by jbrest.
Submission remains selective and subject to approval. Nothing was posted.

## What to retain from the archived drafts

Retain diagnostic evidence conventions, separate accepted/applied/verified status,
product namespaces and explicit recovery-data migration, real consumer builds,
console-session semantics, a minimal standalone UI and the distinction between
resetting app state, unregistering a service and resetting macOS approval.
Retain the embedded-helper identity fixture and real transport-error coverage.

Do not restore the whole 101-file migration map, broad Keepresso runtime breakup,
or the old temporary compiler probe as deliverables required for this stage.
Their useful boundary lessons can be expressed through actual targets and small
compatibility tests without carrying the old project scope forward.

## Checkpoint

Stage 0 remains open. Recommended next action: jbrest has Claude Code review this
file and settles the adapter/removal/experiment amendments. Then update the
planning docs and capture the baseline. No Stage A implementation should begin
before that checkpoint is settled.

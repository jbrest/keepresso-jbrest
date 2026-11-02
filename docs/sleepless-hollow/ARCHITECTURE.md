# Sleepless Hollow: target architecture

Date: 2 November 2026. Status: proposed, pending Codex review. Scope: the
modules Sleepless Hollow (SH) needs, built so Keepresso can adopt them later
without UI changes. Keepresso's adoption layer is described at the end and is
not built in Stages A to D.

## Design principles

1. **Shared modules never import Keepresso.** No shared module depends on
   `KeepressoCore`, the Keepresso app, or any SH module. SwiftPM target
   dependencies enforce this: an undeclared import fails to compile.
2. **Keepresso's semantics stay reachable.** Where Keepresso already has a
   behavior (power-source matching, process matching, schedule boundaries, CPU
   and throughput smoothing and hysteresis), the shared version reproduces it
   exactly by default. Stage E can then switch Keepresso over without changing
   behavior. Any deliberate difference needs a DECISIONS.md entry.
3. **Values, not presentation.** Shared modules hold no localized labels, no
   SwiftUI or AppKit, no factories and no permission prompts. Products supply
   those.
4. **Unavailable is not false.** Every observation carries availability, and
   evaluation is three-state: satisfied, unsatisfied, unknown. A failed reading
   is never turned into a zero or a default.
5. **No hidden clocks or I/O in evaluation.** Evaluators take the condition,
   the samples, the previous state, and an explicit `Date` and `Calendar`.
   They return a verdict and the new state.
6. **Each product owns its saved and wire formats.** Shared model types are not
   written to disk or sent over XPC as they are. Each product maps them into its
   own versioned DTOs. A change to a shared type must never silently change a
   saved file or a protocol.
7. **No imposed execution context.** Shared code is `Sendable` values and
   nonisolated functions. Keepresso keeps `@MainActor`; the SH service keeps a
   serial loop.
8. **Minimal, typed privileged surface.** No generic command runner over XPC.
   Trusted paths, service names and code-signing requirements come from the
   host's own configuration, never from a caller.

## Modules

| Module | Kind | Purpose | Project dependencies | Frameworks |
| --- | --- | --- | --- | --- |
| RuleModel | Shared library | Condition values, sample values, `Observation`, `CombineMode` | None | Foundation |
| RuleEvaluation | Shared library | Pure evaluators, `Verdict`, smoothing state machines, three-state combine | RuleModel | Foundation |
| SystemObservations | Shared library | Readers that acquire samples; no decisions | RuleModel | Foundation, IOKit, Darwin, SystemConfiguration |
| PowerControl | Shared library | Keep-awake holds only: owners, mechanisms, restore journal, verification | None | Foundation, IOKit, Darwin |
| ServiceSupport | Shared library | Helper registration status, XPC peer validation, admin authorization, handshake, structured errors, diagnostics log | None | Foundation, Security, ServiceManagement, Darwin |
| SleeplessContracts | SH library | XPC protocol, versioned policy and status DTOs, capabilities | None | Foundation |
| SleeplessRuntime | SH library | Policy store, supervisor loop, sampling composition, removal transaction, launch handover | All shared modules, SleeplessContracts | Foundation |
| sleepless-helper | SH executable | Root LaunchDaemon host | SleeplessRuntime, ServiceSupport, SleeplessContracts | Foundation |
| SleeplessHollow | SH app | SwiftUI configuration app | SleeplessContracts, ServiceSupport | SwiftUI, AppKit, ServiceManagement |

There is no `SharedSupport` grab-bag module. One gets created only when two
modules need the same utility and it fits neither.

The SH app deliberately does not depend on SleeplessRuntime or the rule
modules: it edits DTOs and asks the service. Only the service evaluates.

### Dependency graph

```text
RuleModel <── RuleEvaluation
    ^
    └──────── SystemObservations

PowerControl      ServiceSupport      SleeplessContracts
      ^                 ^    ^               ^    ^
      |                 |    |               |    |
SleeplessRuntime ───────┘    |               |    |
(also RuleModel, RuleEvaluation, SystemObservations, SleeplessContracts)
      ^                      |               |    |
sleepless-helper ────────────┴───────────────┘    |
SleeplessHollow app ── ServiceSupport ────────────┘
```

### Layout on disk

```text
Sources/Shared/RuleModel/
Sources/Shared/RuleEvaluation/
Sources/Shared/SystemObservations/
Sources/Shared/PowerControl/
Sources/Shared/ServiceSupport/
Sources/Sleepless/SleeplessContracts/
Sources/Sleepless/SleeplessRuntime/
Sources/Sleepless/sleepless-helper/
Sources/Sleepless/SleeplessHollow/        (app, built from its own XcodeGen spec)
Tests/Shared/<Module>Tests/
Tests/Sleepless/<Module>Tests/
SleeplessHollow.yml                       (XcodeGen spec for the SH app)
```

`Package.swift` gains the new targets. It is the only upstream file that
changes before Stage E. `project.yml` is not touched.

## Module contents

### RuleModel

- `PowerSourceCondition` with the same cases and raw values as Keepresso's
  `PowerSourceTrigger.Match` (`onACPower`, `onBattery`, `charging`).
- `ProcessCondition`: name query plus explicit scope (current user or all
  users). Matching semantics follow Keepresso's `ProcessTrigger`. Keepresso's
  `frontmost` mode needs a GUI session; it is modeled but SH does not offer it.
- `SSHSessionCondition` and `ConsoleSessionCondition` (new; see PRODUCT.md).
- `TimeWindowCondition` with Keepresso's `TimeWindowRule` fields and meaning:
  minutes from midnight, weekdays, inclusive start, exclusive end, overnight
  windows owned by the start day.
- `CPUThresholdCondition` and `ThroughputThresholdCondition` with Keepresso's
  units (percent; KiB/s threshold over bytes/s samples).
- `CombineMode` (`any`, `all`).
- `Observation<Value>`: either available (value, time) or unavailable (reason,
  time).
- Sample values: power source snapshot (including unknown provider), process
  snapshot, session snapshot, CPU counters, interface counters, thermal state,
  battery level.

### RuleEvaluation

- `Verdict`: `satisfied`, `unsatisfied`, `unknown`.
- One evaluator per condition type, pure and synchronous.
- CPU and throughput state machines with Keepresso's smoothing weight,
  hysteresis and release fraction. An unavailable sample does not advance the
  state (the archived SH behavior).
- Three-state combine (Kleene logic):
  - `any`: satisfied if any is satisfied; otherwise unknown if any is unknown;
    otherwise unsatisfied.
  - `all`: unsatisfied if any is unsatisfied; otherwise unknown if any is
    unknown; otherwise satisfied.
  - Empty list: follows Keepresso's existing empty-rule behavior.
- What a product does with an aggregate `unknown` is product policy, not
  evaluation. SH's choice is open decision O10. Keepresso's two-state adapter is
  Stage E.

### SystemObservations

Each reader sits behind a protocol, returns `Observation` values and holds no
decision state. Readers:

- Power source (IOKit power sources).
- Process list.
- SSH sessions: must count authenticated sessions only, not pre-auth
  connections. The archived classifier counted any `sshd:` or `sshd-session`
  process. The detection method needs validation on current macOS.
- Console session: whether a real interactive user owns the console, excluding
  `loginwindow` and system or setup accounts. Method and fast user switching
  behavior need validation.
- CPU counters (host statistics) and interface byte counters (`getifaddrs`).
- Thermal state and battery level, for SH safety if O8 adopts it.

Readers needing a GUI session or TCC permission go in a separate subtarget so
the service never links them.

### PowerControl

Scope is keep-awake holds only. Fans, AWDL, keyboard lock, priority boost, wake
schedules and sleep watchdogs stay in Keepresso.

- Owners request or release a typed hold. The module computes the union of
  requests.
- A mechanism protocol, with candidates:
  - IOPMAssertion: macOS releases it when the process exits, so there is no
    restore debt.
  - `pmset disablesleep`: persists, so it needs the journal.
  
  Stage B chooses which mechanism SH uses, and for which situations (O1).
- Results separate requested, applied and verified state.
- Restore journal: write the original value before changing anything; keep
  retrying failed restores without losing the debt.
- Launch reconciliation runs after the host has computed current demand. This
  closes the archived update gap, where `restoreAtLaunch()` released the hold
  before the supervisor started and could re-acquire it.

### ServiceSupport

- Registration status as facts. `SMAppService` status, a live handshake and
  policy readiness are reported separately; none implies another.
- Peer validation:
  - Code-signing requirement builder: team-anchored for signed builds,
    cdhash-pinned for ad-hoc builds.
  - Keep the archived fix that reads `CFBundleExecutable` from `Info.plist`
    directly instead of through a cached `Bundle`.
- Administrator authorization through `admin` group membership, with the
  archived `getgrouplist` fix.
- Handshake: protocol version, capability set and the running helper's build
  identity, all reported by the running process rather than read from the
  bundle on disk.
- Structured errors with operation, domain, code and request ID.
- Diagnostics: correlation IDs, a bounded persistent log, and redaction rules
  (no credentials, screen content or arbitrary command lines).
- Service names, paths and signing requirements come from the host's
  configuration.

### SleeplessContracts

- `SleeplessHelperProtocol` (Objective-C XPC). It starts at protocol version 1
  under SH's own service identity, with no compatibility with Keepresso's
  helper protocol.
- `PolicyDTO`, version 1:
  - enabled flag, combine mode and conditions;
  - its own Codable shape, mapped to RuleModel inside SleeplessRuntime.
- `StatusDTO`:
  - accepted policy and revision;
  - per-condition verdict and availability, and aggregate demand;
  - hold requested, applied and verified, plus the last error.
- Capability list.

### SleeplessRuntime

- Policy store: a root-owned file, atomic writes, a schema version, and
  rejection of malformed or oversized input.
- Supervisor: a serial loop that polls every 3 s by default. Each cycle samples
  once, evaluates once and applies holds once. Presentation reads the result
  and never advances it.
- Removal transaction:
  1. Persist the disabled policy.
  2. Release the hold and verify the release.
  3. Block re-acquisition.
  4. Report ready to unregister.
  
  Fixes carried in (see SOURCE-INVENTORY.md): only an administrator can start
  removal, and cancelling it restores the previous enabled state.
- Launch handover: load policy, sample, evaluate, then reconcile the journal
  against current demand.
- Idle exit only when there is no demand, no pending restore debt and no
  removal in progress.
- Safety pause on thermal or battery thresholds, if O8 adopts it.

## Later: Keepresso adoption (Stage E, not in current scope)

Designed now so that Stages A to D don't block it; built only after SH works
and with the user's approval:

- `KeepressoCore` re-exports the shared modules and keeps the old type names as
  type aliases or thin wrappers. The 42 files that import `KeepressoCore` keep
  compiling with no UI edits.
- The two-state adapter maps `Verdict` to Keepresso's `Bool` per condition type,
  reproducing Keepresso's current treatment of missing readings exactly (O11).
- Keepresso's triggers become thin wrappers over the shared evaluators.
  Equivalence tests run old and new side by side, then the duplicated code is
  deleted.
- Keepresso's helper may adopt PowerControl and ServiceSupport later still. Its
  XPC protocol and service identity do not change in Stage E.

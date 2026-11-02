# Sleepless Hollow: validation and evidence plan

Status: acceptance reference for Stages A to D of
[MIGRATION-PLAN.md](MIGRATION-PLAN.md). Carried forward on 2 November 2026 from
the archived `docs/MODULAR-VALIDATION-PLAN.md` (originally generated with OpenAI
Codex under jbrest's direction). Rows about Keepresso parity apply from Stage E.

## Responsibility and evidence

The coding agent owns source inventory, interface design, implementation,
automated checks, instrumentation, test procedures and evidence analysis. The
user supplies product decisions, required macOS authentication and physical or
remote-session interactions that cannot be exercised automatically. A successful
UI message is not accepted as proof of the underlying operation.

Each installed test must have prerequisites, numbered steps, expected results,
stop conditions, a correlation ID and an automatic evidence bundle. Read-only
collection must be separated from state changes. A script must report its limits
and fail when inspection fails; it must not convert an inspection error into
“absent” or label retained macOS approval as a verified first-ever install.

## Baselines

- Upstream baseline: to be captured in Stage 0 on `upstream/main` (`7ea73a6`).
  Record toolchain, SDK, OS and the passing test count in [NOTES.md](../../NOTES.md).
- Archive reference: the archived fork passed 1,223 tests (1,210 Core plus 13
  `HelperConnectionTests` run separately). That count includes fork-only
  Headless tests, so it is not the upstream baseline.
- Archived installed evidence (protocol 16, team-signed): administrator
  recognized, enabled policy saved with matching readback, unregister succeeded.
  This supports the ServiceSupport approach; it is not SH acceptance.

## Automated acceptance matrix

Stages A to D (shared modules and SH):

| Area | Required check | Evidence to retain |
| --- | --- | --- |
| Keepresso untouched | Invariant I1 diff is empty | Command output per stage |
| Provenance | Every ported unit listed in SOURCE-INVENTORY.md with source and revision | Inventory plus the provenance check after each rebase |
| Module boundaries | Each target builds with only its declared dependencies | `swift build` per target |
| Conditions | Ported semantics match Keepresso: matching, smoothing, hysteresis, schedule boundaries, any/all; three-state handling of unavailable readings | Ported Keepresso tests plus new three-state tests |
| Observations | Readers report unavailable instead of a default value; SSH pre-auth connections are not sessions | Fixture tests plus read-only smoke runs on a real Mac |
| Power control | Multiple owners, exact prior values, failed operations/readback and restore debt | Fake backend traces plus bounded installed checks |
| Service | Signature checks, administrator checks, protocol negotiation and real errors | Client/helper identities and transport traces |
| Packaging | SH app and helper signing, identifiers and embedded plist consistent | Build records and signature verification |

Stage E (Keepresso adoption, later):

| Area | Required check | Evidence to retain |
| --- | --- | --- |
| Settings | Existing defaults, import/export, malformed inputs and old formats remain equivalent | Versioned fixtures and decoded/output comparisons |
| Conditions | Every Keepresso rule retains matching, grace, smoothing, scope, any/all and time/DST behavior through the two-state adapter | Existing tests plus adapter equivalence cases |
| Session behavior | Manual/timed/trigger/lease precedence, safety pauses, reminders and end actions unchanged | Fixed-clock state/effect traces |
| Integrations | CLI exits/output, MCP protocol, widget commands, URLs and agent hooks unchanged | Fixture requests/replies and consumer builds |
| UI/localization | No edits to UI files; all 15 languages unchanged | Diff of app-shell sources plus localization checks |

## Installed acceptance matrix (Stage D)

| Scenario | What the user does | What instrumentation must establish |
| --- | --- | --- |
| Install/approval | Launch installed copy, enable feature, authenticate if needed | Correct build/path, registration changes, handshake, policy readback |
| Conditions | Perform controlled positive/negative transitions | Observations, evaluated decision and actual applied/released hold |
| Removal | Remove while inactive, then during a confirmed enforcing hold | Disabled accepted policy, verified release, unregister and launchd absence |
| Update | Install distinct build over prior version | Which running helper answers, handover and retained policy/approval |
| Crash/recovery | Terminate a specified owned test process | Owner cleanup, restoration debt and eventual readback |
| SSH | Connect/disconnect and test listener-only/no-session state | Session classification rather than daemon existence |
| Console session | Log in, lock, disconnect Screen Sharing, reconnect, then explicitly log out | Login remains active after disconnect/lock; demand ends on logout when no other condition matches |
| Reboot/no console login | Reboot, unlock FileVault, leave GUI logged out | Helper starts, loads policy and enforces without GUI dependency |
| Two products | Run Keepresso and SH together | No shared-state corruption; both services hold and release independently |

Do not run a sleep/reboot/logout test while relying on that same session for
uninterrupted agent work. Procedures must provide a recovery/reconnection route
and identify which checks require a separate session or machine.

## Sleepless Hollow session requirement

The requested condition is **a macOS console user session remains logged in**,
not an active VNC connection. Closing Screen Sharing does not by itself mean
logout. Locking also leaves the session logged in. An actual logout ends this
condition; overall demand still respects any other matching condition.

The first design must distinguish an interactive console user from loginwindow
and system/setup accounts, and specify fast-user-switching behavior. Separate
virtual screen-sharing sessions require explicit investigation rather than being
silently equated with the console. The source of the original login does not need
to be detected for the console-session condition. No implementation has been
added yet, and the current SSH rule does not cover this requirement.

## Boundary evidence

Module boundaries are enforced by SwiftPM target dependencies: an import a
target does not declare fails to compile. The archived
`tools/architecture/check_boundaries.py` probe is not carried forward.

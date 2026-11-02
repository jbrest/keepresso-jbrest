# Sleepless Hollow: product and UI specification

Status: proposed behavior; not implemented. Carried forward on 2 November 2026
from the archived draft `docs/SLEEPLESS-HOLLOW-UI.md` (tag
`archive/headless-in-keepresso-2026-11-02`), originally generated with OpenAI
Codex under jbrest's direction. Open choices are tracked in
[DECISIONS.md](DECISIONS.md); edit this file when one is settled.

Sleepless Hollow (SH) is a separate app with its own background service.
Keepresso's existing UI is unchanged. Historical requirements and test history
for the earlier in-Keepresso design are in the archived
`docs/HEADLESS-MODE-SCOPE.md`; where they conflict with this file, this file wins.

## Product model

Sleepless Hollow configures a machine-wide service. Its window can be closed or
the configuration app quit while enabled policy continues. It does not contain
Keepresso's local/app-running rules or ask users to configure the same feature
in two places. FileVault must already have been unlocked after boot; the service
cannot enforce policy while the operating system has not started.

Use one configuration window for first launch and later use, with a small
optional menu-bar status entry rather than a separate rule-management model.
The menu-bar entry is a draft product choice; no requirement to keep it running
is imposed on service operation.

## Main window

```text
Sleepless Hollow

Enable Sleepless Hollow                         [ switch ]
Keeps this Mac awake when your conditions match,
even when this app is closed or no one is logged in.

[ Accepted state / pending approval / error, in plain language ]

Keep awake when:                       Match [ Any / All ]
[ ] On AC power       [ ] On battery       [ ] Charging
[ ] SSH session active
[ ] Console user logged in
[ ] Process running        [ process query ... ]
[ ] During schedule        [ days and time ... ]
[ ] CPU above              [ threshold ... ]
[ ] Network activity above [ threshold ... ]

Current result: Waiting for a matching condition
Last checked: ...                         [ Details ]

Background service: Ready                  [ Remove ]
                                          [ Copy diagnostics ]
```

Use ordinary macOS Preferences body text and compact controls. Status is visible
without expanding a helper section. “Background service” is the user-facing name;
technical helper details belong in diagnostics. Individual rule values have
inline editing rather than cards added through repeated menus. Multiple process
queries or schedules may reveal a compact additional-row action when selected.
The main window can scroll; it should not expand unpredictably with every rule.

## First launch and enabling

Initially the mode is off. The enable switch is the sole start control: there is
no second Start or Save button. Turning it on initiates service registration if
necessary, then shows progress or the approval action inline. Do not add an app
confirmation before the necessary macOS authentication/approval steps.

Once the helper answers with compatible capabilities, load the machine policy,
submit the enabled state, verify accepted readback, and show condition controls.
An enabled policy with no conditions does not hold the machine awake. Show
“Enabled: choose conditions” rather than implying active enforcement.

The switch is unavailable while its submitted operation is in flight, not
permanently disabled merely because the service has not yet been installed.
A standard account receives an explicit authorization result; macOS approval of
the installation by another administrator does not silently grant that account
policy-editing permission. The final fresh-authentication policy is still open.

If approval is required, show Open System Settings inline and monitor progress.
Return automatically to the ready state after a live handshake; do not require a
checker acknowledgement. A separate attention window, when needed outside this
page, briefly shows verified success and dissolves automatically.

## Editing, saved state and failures

Valid condition edits autosave after a short debounce. Show pending state until
the helper accepts the edit and readback matches. Invalid process/schedule values
remain visible with a local explanation and are not submitted. The previously
accepted policy continues to govern; the UI must state when edits are not saved.

Do not show green success just because the service is installed. Show accepted
policy and observed enforcement separately. A failed enable restores the switch
to the accepted state, retains the attempted settings for Retry and presents the
actual error. Retry resubmits the attempted change. Diagnostics persist even if
a later refresh clears the visible error.

## Runtime status

| State | Main message | Meaning |
| --- | --- | --- |
| Disabled | Off | Machine policy disabled; service may remain installed |
| Installing/checking | Setting up background service | Registration or handshake in progress |
| Approval pending | Approval needed in System Settings | Service is not yet ready to accept/enforce policy |
| Enabled, no conditions | Enabled: choose conditions | Policy accepted; no hold requested |
| Enabled, no matching condition | Waiting for conditions | Samples available; no current keep-awake demand |
| Enabled, matching and verified | Keeping this Mac awake | Demand and actual operation result agree |
| Unavailable observation | Some conditions cannot be checked | Show which readings are missing and the resulting demand policy |
| Operation failure | Could not apply the keep-awake setting | Accepted policy is distinct from failed enforcement |
| Incompatible helper | Background service needs updating | Answering process is older/incompatible; show supported update path |

Details show per-condition observation, availability, last observation and why
aggregate demand is true/false/unknown. State whether this service holds the Mac
awake; do not claim the whole Mac will sleep when other applications hold it.

## Console-session condition

“Console user logged in” means an interactive macOS console user session exists.
It is not a live Screen Sharing/VNC network connection, nor an SSH login.
Disconnecting Screen Sharing or locking the screen does not end the condition.
Logging out the console user does. The condition does not need to detect whether
the user originally logged in locally or remotely.

Initial proposed scope is any qualifying console user, rather than only the
administrator who configured the policy. Exclude loginwindow and setup/system
accounts. Explain this in the condition's help text. Fast user switching,
separate virtual sessions and detection-failure behavior need validation before
implementation; do not infer them from a process name or an open port.

## Disable, remove, close and quit

Turning the mode off saves a disabled policy and verifies release of the
service's hold. Keep the service installed, avoiding repeated authentication and
registration churn. Remove remains an explicit action at the bottom of the page.
This default installation policy is proposed for review.

Remove works whether mode is off or enabled. It first persists disabled policy,
releases and verifies effects, blocks reacquisition and only then unregisters.
If preparation fails, removal stops and reports why. If unregister fails, show
the actual registered state; do not claim removal. Successfully removed means
no registered service, not necessarily deletion of macOS's retained approval
entry. Do not promise a reboot erases that entry.

Closing the window or quitting this configuration app does not disable an
accepted enabled policy. Make that clear near the switch and in the Quit action.
No recurring warning or extra confirmation is needed once the distinction is
clear. Disabled-policy inspection must not reinstall the service automatically.

## Instrumentation and user acceptance

Every state-changing action receives a correlation ID. Collect app/helper build
identity, registration, handshake, caller authorization, policy revision/readback,
observation availability, requested/applied effects and errors. Retain a bounded
persistent log and a Copy diagnostics action without a manual capture session.
Do not capture credentials, screen content, prompts or arbitrary process command
lines in user-facing reports.

Acceptance scripts will drive synthetic conditions where possible and collect
before/after readback. User procedures cover authentication, visual behavior,
lock/disconnect/reconnect/logout and reboot. Tests that terminate a login session
must not be run while relying on it for uninterrupted agent work.

## Review choices

Tracked as open decisions O5 to O9 and O13 in [DECISIONS.md](DECISIONS.md).
None of them proposes a change to Keepresso.

## Provisional visual direction

Selected: **option C, the third concept** in the
horseman concept sheet (`docs/assets/sleepless-hollow/horseman-concepts-abc.png` at the archive tag).
The direction is a minimal black headless rider on a moving horse, with a short
cape and an ivory background. This is a retained concept for later refinement,
not a finished app or menu-bar asset. No existing application icon is replaced.

# A7 session validation handoff

Status: read-only prototype and fixtures implemented. These tests are not yet
permission to enable a policy or change a session. Review with jbrest before
performing any SSH login, second-user, lock, Screen Sharing or logout test.
Never lock or log out the session running the coding agent.

## What is implemented

ConsoleSessionReader reads public utmpx accounting, selects active `console`
records and excludes system/setup accounts using account lookup. Lookup failure,
malformed records and accounting failure yield unavailable. Its current result
is evidence about console accounting, not a validated promise about every GUI
session. O5 remains open.

SSHSessionReader defaults to unsupported. An injected evidence seam exercises a
source-informed classifier, including legacy and split OpenSSH, pre-auth,
monitor processes, non-PTY connections and SFTP child deduplication. No live
backend supplies that seam. Executable identity, visibility, process races and
actual title formats must be validated before enabling one. An empty fixture
list is not evidence that a live machine has no sessions.

Neither reader is wired to Keepresso or a running SH service.

## Read-only capture

From this checkout, run:

```sh
python3 tools/probe-session-state.py > /tmp/sh-session-before.jsonl
python3 tools/probe-session-state.py --samples 10 --interval 1 > /tmp/sh-session-during.jsonl
```

The tool never connects or changes sessions. Each subprocess has a three-second
limit; samples are capped at 30, with at most two seconds between captures.
It emits JSON lines containing console record counts, a coarse current-owner
category and SSH process IDs, executable paths and title-shape categories. It
omits usernames, raw commands, remote addresses and console UUIDs. Unreadable
or exited PIDs are counted. These captures remain diagnostic evidence, not an
authentication verdict or proof of complete process visibility.

The actual Swift console prototype can be exercised separately:

```sh
swift test --filter realConsoleAccountingReadOnlySmoke
```

Expect an available user count for normal readable accounting. Record an
unavailable result as a failure to investigate, never as zero logged-in users.
The smoke test does not prove locking, switching or virtual-session behavior.

## Interactive cases, pending jbrest's approval

Use an independent control session that will remain logged in. Label each
capture with the action performed; do not infer user actions from the counts.
Use existing Remote Login configuration only. Do not enable it or change SSH
configuration as part of these instructions.

| Case | Action after approval | Evidence needed |
| --- | --- | --- |
| SSH baseline | Capture with no test SSH connection | Record existing connections; absence of test connections is not assumed from process names |
| Pre-auth | Hold a TCP connection to the SSH service without authenticating, from another terminal/device | Capture `[accepted]`/auth/monitor lifecycle without counting it as authenticated; close it afterward |
| Authenticated PTY | Log in from another device with `ssh -t USER@HOST`; leave it open | Identify real executable path, parent/child relationship and post-auth title; capture before/after `exit` |
| No PTY / forwarding | Use `ssh -N USER@HOST`, then disconnect that client | Determine whether a bare user title persists for authenticated forwarding-only connections |
| SFTP / multiple channels | Hold an SFTP connection and multiple channels on one connection | Count connections rather than SFTP workers or PTYs; verify no double counting |
| Screen Sharing disconnect | Disconnect the viewing client while the remote user stays logged in | Console accounting should still show the logged-in user; no dependency on a VNC socket |
| Lock | Lock only a separate test session | Determine accounting persistence; do not lock the agent's session |
| Fast switching | Log in a second user and switch between users and login window | Determine whether every logged-in GUI session has a console record; compare current-owner API separately |
| Logout | Log out only the disposable second user | Its record should disappear without disturbing the agent's session |
| Separate virtual session | Create a separate Screen Sharing GUI session | Determine whether/how it appears in accounting; do not assume it is the physical console |

No unattended script should perform those actions. If the public accounting
source misses required GUI sessions, choose a supported complementary source or
an agent registration design at review; do not parse undocumented SessionInfo
keys into a production contract. Do not advertise the console condition until
its scope and tested behavior are agreed under O5.

For SSH, a production backend must establish identity independently of mutable
command strings, handle incomplete access and process exit/reuse races, cover
the supported OpenSSH versions and demonstrate authentication transitions. If
that cannot be established reliably, keep returning unsupported. A listener or
an open port never satisfies the condition.

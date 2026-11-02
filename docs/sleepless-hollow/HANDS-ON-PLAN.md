# Hands-on test plan: SSH, Screen Sharing, logout and reboot

Date: 2 November 2026. Status: draft by Claude Code with jbrest. Codex adds the
exact commands and tooling (see "Codex tasks" at the end). Claude Code reviews
the result before sitting 3 or any B1 install.

## The setup this plan assumes

Read-only checks on 2 November 2026 found:

| Fact | Consequence |
| --- | --- |
| The test machine is the **Studio** (`Jeremys-Mac-Studio`, Mac16,9), headless, macOS 26.5 | Test on the Studio itself. It is the real target, and a Mac with a display behaves differently (no virtual display). |
| jbrest reaches it only by **Screen Sharing** (virtual 4K display) or **SSH** | The other Mac (the **laptop**) is the remote device for every step. |
| Claude and Codex run **inside jbrest's GUI session** on the Studio | Logging out jbrest kills them. Logout and reboot steps are driven from an SSH session inside `tmux`, which survives a GUI logout. |
| **FileVault is on**; `fdesetup authrestart` is supported | A normal reboot stops at the FileVault unlock screen, which cannot be reached remotely. Use `authrestart` for reboots. |
| **Remote Login is on**, inetd-style: no `sshd` process exists until a connection arrives | There is no idle listener process at all. Every `sshd`-family process belongs to a live connection. |
| **Screen Sharing holds a "Remote user is connected" sleep block** while connected | Every power and sleep observation must be made with Screen Sharing *disconnected*, watched over SSH. |
| One user account (`jeremybrest`) | A disposable second account is needed for the switching and second-session cases. |

**No monitor is needed.** Keep a USB keyboard within reach for sitting 3 only.
If a reboot ever lands on the FileVault screen, a single-account Mac has the
password field focused, so the password can be typed blind followed by Return.
That is why the second test account is deleted before sitting 3. It
may also have been given FileVault access, which would turn the unlock screen
into a user picker.

## Conventions

- **Control channel** (from sitting 2 on): a laptop Terminal window running
  `ssh jeremybrest@Jeremys-Mac-Studio.local`, then `tmux new -A -s probe`, with
  the probe recording continuously to a file. Detach with `Ctrl-b d` and
  reattach with `tmux attach -t probe`. The control session is itself an SSH
  connection. Its process is labeled in the captures, and it is not counted as
  a test connection.
- **Marking steps.** Before each numbered step, run the probe's "mark" command
  with the step number, so the capture file records what was done and when.
  Never infer an action from the counts alone.
- **Wait times.** "Hold" means leave it in place for 30 seconds before the next
  action, so at least a few samples land in each state.

## Sitting 0: preparation (about 10 minutes, no risk)

1. On the laptop, open Terminal and run
   `ssh jeremybrest@Jeremys-Mac-Studio.local`. Confirm it logs in, then `exit`.
   If it asks for a password rather than using a key, note that. Step 1.2 needs
   to know.
2. On the Studio (over Screen Sharing), create a **standard** user `shtest` in
   System Settings > Users & Groups, with a throwaway password. It is deleted in
   sitting 2, step 2.9.
3. Confirm the laptop can open Screen Sharing to the Studio as `shtest` (Finder
   > Network, or `vnc://Jeremys-Mac-Studio.local`). Choosing "log in as
   yourself" gives `shtest` its own virtual session. Cancel without logging in.

## Sitting 1: SSH channel (about 25 minutes; Claude and Codex keep running)

Codex runs the probe locally on the Studio for this sitting, so the only SSH
connections are the ones made deliberately. jbrest stays on Screen Sharing; that
doesn't affect SSH counts.

| Step | On the laptop | Purpose |
| --- | --- | --- |
| 1.0 | Nothing connected | Baseline: zero SSH processes expected |
| 1.1 | `nc Jeremys-Mac-Studio.local 22`. A version banner appears. Hold, then `Ctrl-C`. | **U1:** a connection that never authenticates. Does the Keepresso preset's match fire? |
| 1.2 | `ssh -o PubkeyAuthentication=no jeremybrest@Jeremys-Mac-Studio.local`. Stop at the password prompt and **do not type it**. Hold, then `Ctrl-C`. | U1: pre-auth with a username, the `[priv]` monitor case |
| 1.3 | `ssh jeremybrest@Jeremys-Mac-Studio.local`, logged in. Hold, then `exit`. Hold after. | Normal interactive session, and its cleanup on a clean exit |
| 1.4 | `ssh -N jeremybrest@Jeremys-Mac-Studio.local`. Hold, then `Ctrl-C`. | Authenticated, no shell (forwarding-only) |
| 1.5 | `ssh jeremybrest@Jeremys-Mac-Studio.local sleep 45`. Let it finish. | Authenticated command without a terminal |
| 1.6 | Two Terminal windows, each `ssh ...` logged in. Hold. Exit one, hold. Exit the other. | Counting several connections, and partial disconnect |
| 1.7 | `sftp jeremybrest@Jeremys-Mac-Studio.local`. Hold, then `bye`. | SFTP: one connection, not double-counted |
| 1.8 | `ssh ...` logged in, then **turn off the laptop's Wi-Fi** (no `exit`). Leave it off for 5 minutes, then turn it back on. | Dirty disconnect: how long do the Studio's processes linger after the client vanishes? This matters for SH, which would keep the Mac awake for that long. |
| 1.9 | Optional: on the **Studio**, outgoing `ssh -T git@github.com`, or `ssh` to the laptop if its Remote Login is on. Hold if possible. | Confirms outgoing client processes (`ssh`) never match |

## Sitting 2: Screen Sharing and console sessions (about 30 minutes)

Claude and Codex keep running; nothing in this sitting logs out `jeremybrest`.
Start the control channel first, with the probe recording.

| Step | Action | Purpose |
| --- | --- | --- |
| 2.0 | Connected by Screen Sharing as `jeremybrest` | Baseline: one console user |
| 2.1 | Close the Screen Sharing window on the laptop. Wait 2 minutes, watching over the control channel. Reconnect. | Disconnecting the viewer must not end the console session |
| 2.2 | In the Studio session, lock the screen (`Ctrl-Cmd-Q`). Disconnect Screen Sharing for 2 minutes, reconnect, unlock. | A locked session is still logged in. Locking does not stop running programs, so the agents are unaffected. |
| 2.3 | From the `jeremybrest` session, Apple menu > Lock Screen, or the menu-bar user switcher > Login Window. Wait 1 minute, then log back in as `jeremybrest`. | Login window owns the screen while `jeremybrest` stays logged in |
| 2.4 | Menu-bar user switcher > `shtest`, log in. Hold. Switch back to `jeremybrest`. | Fast user switching: two logged-in users |
| 2.5 | Switch to `shtest` again and log it out (Apple menu > Log Out). Back at `jeremybrest`. | One of two users logs out |
| 2.6 | From the laptop, open a **second** Screen Sharing connection and choose to log in as `shtest` in its own session, while `jeremybrest` stays logged in. Hold. | Separate virtual session: does it appear as a console user at all? |
| 2.7 | Close that `shtest` window without logging out. Wait 2 minutes. | Disconnected virtual session: still logged in? |
| 2.8 | Reconnect as `shtest` and log out. | Virtual session logout |
| 2.9 | Delete the `shtest` account (System Settings > Users & Groups). | Keeps the FileVault unlock screen single-user for sitting 3 |

## Sitting 3: logout and "nobody logged in" (about 45 minutes; keyboard nearby)

The agents are closed for this sitting. jbrest works from the laptop only.
Claude Code reviews this sitting's final commands first.

1. **3.0 Prep.**
   - Quit Codex and Claude on the Studio.
   - Start the control channel with the probe recording, and detach `tmux`.
   - Keep the laptop Terminal open.
2. **3.1 Log out over Screen Sharing.** Log out `jeremybrest` (Apple menu > Log
   Out). Screen Sharing now shows the login window. Disconnect Screen Sharing.
   - Over the control channel: the console user count must be zero, and SSH
     still works.
   - This is the state SH exists for.
3. **3.2 Log back in.** Reconnect Screen Sharing and log in at the login window.
   Disconnect again, and confirm the console user is back.
4. **3.3 Reboot to nobody logged in.**
   - From the control channel: `sudo fdesetup authrestart`, which unlocks
     FileVault once for this restart.
   - Wait 3 minutes, then `ssh` in again from the laptop. Don't log in over
     Screen Sharing yet.
   - Start the probe. Expect zero console users, with SSH working.
5. **3.4 Recovery, if needed.** If SSH doesn't answer within 10 minutes, the
   Studio is probably waiting at the FileVault screen. Plug in the keyboard,
   type the `jeremybrest` password and press Return. SSH should answer about a
   minute later.
6. **3.5 Finish.** Log in over Screen Sharing and restart Codex and Claude. Copy
   the capture files into the repo, per the evidence rules.

## Sitting 4: B1 power experiment (after the pre-B1 review)

Not scheduled until Codex's experiment design is reviewed. Constraints already
known:

- **Observe sleep only with Screen Sharing disconnected.** Its sleep block would
  mask everything.
- Idle sleep is set to 60 minutes. Shortening it for the test is a system
  setting change. It needs approval and a recorded restore step.
- Wake on network access is on (`womp 1`), so a probe arriving while the Studio
  sleeps may wake it. Confirm sleep afterwards from `pmset -g log`, not from a
  connection failing.
- The Studio has no lid and no battery. The plan's lid-closed and battery cases
  can only run on a laptop. Defer them, or drop them for an SH version that
  targets desktops.

## Codex tasks

1. Extend `tools/probe-session-state.py`, read-only as before:
   - a `--mark STEP` option that appends a labeled line to the capture file;
   - a continuous mode (for example, every 5 seconds for up to 2 hours) that
     writes to a named file and is safe to leave running in `tmux`;
   - a summary of `pmset -g assertions`, giving the owner process and assertion
     name only;
   - a label on the control channel's own `sshd` processes, so they are not
     counted as test connections.
   
   Keep the existing privacy rules.
2. Add the exact `mark`, start and stop commands to each step above. Keep this
   document's structure.
3. Check whether macOS 26 can unlock FileVault over SSH after an ordinary
   reboot. If it can, add it as a recovery option. Keep `authrestart` as the
   primary path either way.
4. Add the B1 experiment design as sitting 4, per the brief.
5. Stop for the Claude Code review before jbrest runs sitting 3 or 4. Sittings
   0 to 2 can run once Codex has finished tasks 1 and 2.

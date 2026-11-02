# Hands-on runbook: sittings 0 to 2

What jbrest pastes and does. The design and reasons are in
[HANDS-ON-PLAN.md](HANDS-ON-PLAN.md). Sittings 3 and 4 come later, after review.

**Studio** = the Mac Studio (reached by Screen Sharing). **Laptop** = the MacBook.

## Ground rules for every sitting

- **Install nothing.** The laptop already has everything (Terminal, ssh, sftp,
  nc, Screen Sharing). The Studio already has tmux and Python.
- **VS Code, Claude and Codex on the Studio:** leave them open throughout
  sittings 0 to 2. Don't give them work while a sitting is running.
- **Laptop:** plug it into power. The script keeps it awake by itself while it
  runs. Keep its Terminal window visible.
- **No other connections to the Studio** during sitting 1: no other Terminal
  tab logged in to it, no VS Code Remote, no file sharing.
- **Timers are in the script.** It tells you when to act and when to wait. When
  it shows `>> ... Then press Return.`, do the thing, then press Return.
- **To abort:** press `Ctrl-C`. If Wi-Fi was off, the script turns it back on.

## Sitting 0: preparation (about 15 minutes)

**A. On the Studio**, over Screen Sharing as jeremybrest:

1. System Settings > Users & Groups > **Add User...**
   - New account: **Standard**
   - Full name: `SH Test`, account name: `shtest`
   - A throwaway password. Write it down for sitting 2.
   - If macOS offers to let this user unlock the disk (FileVault), that's fine.
     The account is deleted at the end of sitting 2.
2. System Settings > General > Sharing > **Screen Sharing (i)**. Under "Allow
   access for", make sure `shtest` can connect: either "All users", or add
   `SH Test` with **+**.
3. System Settings > Control Center > **Fast User Switching** > Show in Menu
   Bar: **Always** (or "Show in Menu Bar").

**B. On the laptop**, open Terminal and paste this one line:

```sh
scp jeremybrest@Jeremys-Mac-Studio.local:dev/keepresso-jbrest/tools/hands-on/laptop-runner.zsh ~/ && zsh ~/laptop-runner.zsh preflight
```

It should end with `Preflight passed.` If anything says FAILED, stop and tell
Claude. Note what it printed for step 1.8: whether it can switch Wi-Fi itself.

**C. On the laptop**, check that shtest can use Screen Sharing:

1. In the Screen Sharing app: Connect to `Jeremys-Mac-Studio.local`.
2. Sign in as `shtest` with its password.
3. When it offers "log in as yourself" or "ask for permission", click
   **Cancel**. Seeing the offer is the check.
4. Your existing jeremybrest Screen Sharing window is unaffected.

## Sitting 1: SSH (about 35 minutes)

On the laptop, in Terminal:

```sh
zsh ~/laptop-runner.zsh 1
```

- **Screen Sharing:** optional. Stay connected if you like. It drops at step
  1.8 when Wi-Fi goes off. Reconnect afterwards if you want.
- **Every step runs by itself.** You only press Return at the start (and at
  1.8, if the preflight said Wi-Fi can't be switched automatically).
- **Step 1.8:** the laptop's Wi-Fi goes off for about 5 minutes. Don't touch
  it. The script turns it back on.
- **At the end, the recorder keeps running on the Studio** for up to 4 hours,
  and it keeps the Studio awake while it does. That shows how long a vanished
  session lingers. Tell Claude when you're done, and it reads the results.
- Wait at least **2.5 hours** after sitting 1 before starting sitting 2, or do
  sitting 2 another day. Starting sitting 2 stops the sitting 1 recording.

## Sitting 2: Screen Sharing and sessions (about 40 minutes)

Before starting:
- Connect Screen Sharing to the Studio as jeremybrest.
- Have the shtest password ready.

On the laptop, in Terminal:

```sh
zsh ~/laptop-runner.zsh 2
```

The script tells you each action. You will:
- quit and reopen Screen Sharing (`Cmd-Q`) several times;
- lock the Studio's screen;
- go to the login window and log back in;
- switch to shtest and back;
- open a separate shtest Screen Sharing session;
- finally, delete shtest.

When the script asks you to act inside the Studio, do it in the Screen Sharing
window. Then switch back to the laptop's Terminal to press Return.

The last step deletes shtest: System Settings > Users & Groups > shtest (i) >
Delete User, choosing to delete the home folder.

## If the script changes

If Claude updates the script, paste the `scp ...` line from sitting 0 step B
again to fetch the new copy.

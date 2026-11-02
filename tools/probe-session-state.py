#!/usr/bin/env python3
"""Bounded read-only A7 diagnostics. Never opens or changes a session.

JSON lines omit usernames, command contents, addresses and console UUIDs.
This captures candidate evidence, not a production authentication verdict.
"""
import argparse
import ctypes
from datetime import datetime, timezone
import json
import re
import subprocess
import time


def run(argv, stdin=None):
    try:
        result = subprocess.run(argv, input=stdin, text=True, capture_output=True, timeout=3)
        if result.returncode:
            return None, f"exit-{result.returncode}"
        return result.stdout, None
    except (OSError, subprocess.TimeoutExpired) as error:
        return None, type(error).__name__


def title_shape(title):
    # Names are intentionally discarded. These are syntax labels only.
    for state in ("[accepted]", "[rexeced]", "[net]", "[session-auth]", "[session-auth early]"):
        if title.endswith(state):
            return state
    for state in ("[preauth]", "[priv]", "[listener]"):
        if state in title:
            return state
    if re.search(r"(?:sshd|sshd-session): [^\s@]+@(?:ttys\d+(?:,ttys\d+)*|notty|internal-sftp)$", title):
        return "post-auth-title-candidate"
    if re.fullmatch(r"(?:sshd|sshd-session): [\w.-]+", title):
        return "bare-user-title-candidate"
    return "unrecognized"


def capture():
    report = {"time": datetime.now(timezone.utc).isoformat(), "prototype": True}
    who, error = run(["/usr/bin/who"])
    report["loginAccounting"] = {"error": error} if error else {
        "consoleRecords": sum(1 for row in who.splitlines() if len(row.split()) >= 2 and row.split()[1] == "console"),
        "otherRecords": sum(1 for row in who.splitlines() if len(row.split()) >= 2 and row.split()[1] != "console"),
    }
    console, error = run(["/usr/sbin/scutil"], "show State:/Users/ConsoleUser\n")
    if error:
        report["currentConsoleOwner"] = {"error": error}
    else:
        match = re.search(r"^\s*Name\s*:\s*(.+)$", console, re.MULTILINE)
        name = match[1].strip() if match else None
        report["currentConsoleOwner"] = {"kind": (
            "unavailable" if name is None else
            "system-or-setup" if name in ("root", "loginwindow", "mbsetupuser") or name.startswith("_") else
            "user-candidate"
        )}
    ps, error = run(["/bin/ps", "-axww", "-o", "pid=,ppid=,args="])
    if error:
        report["sshProcessEvidence"] = {"error": error}
        return report
    # Check executable paths independently of mutable process titles. This is
    # still racy and incomplete on permission errors, so never a policy backend.
    libproc = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
    libproc.proc_pidpath.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32]
    libproc.proc_pidpath.restype = ctypes.c_int
    paths = {"/usr/sbin/sshd", "/usr/libexec/sshd-session", "/usr/libexec/sshd-auth"}
    rows, denied = [], 0
    for line in ps.splitlines()[:4096]:
        parts = line.split(None, 2)
        if len(parts) != 3:
            continue
        try:
            pid, parent = int(parts[0]), int(parts[1])
        except ValueError:
            continue
        buffer = ctypes.create_string_buffer(4096)
        if libproc.proc_pidpath(pid, buffer, len(buffer)) <= 0:
            denied += 1
            continue
        executable = buffer.value.decode("utf-8", errors="replace")
        if executable in paths:
            rows.append({"pid": pid, "parentPID": parent, "executable": executable,
                         "titleShape": title_shape(parts[2])})
    report["sshProcessEvidence"] = {"rows": rows, "unreadableOrExitedPIDs": denied,
                                    "truncated": len(ps.splitlines()) > 4096,
                                    "productionVerdict": "unsupported"}
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--samples", type=int, default=1)
    parser.add_argument("--interval", type=float, default=1)
    args = parser.parse_args()
    if not 1 <= args.samples <= 30 or not 0.1 <= args.interval <= 2:
        parser.error("samples must be 1..30; interval must be 0.1..2 seconds")
    for index in range(args.samples):
        print(json.dumps(capture(), sort_keys=True), flush=True)
        if index + 1 < args.samples:
            time.sleep(args.interval)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Read-only hands-on recorder for the Studio. Run it through hands-on.sh.

Every few seconds it appends one JSON line: the A7 probe's privacy-preserving
capture, plus a summary of `pmset -g assertions` that keeps only the owning
process name and the assertion type. Assertion names, usernames, addresses
and command contents are never written. It changes no system state and stops
by itself after --max-hours.
"""
import argparse
from datetime import datetime, timezone
import importlib.util
import json
import os
import re
import signal
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
PROBE_PATH = os.path.join(HERE, "..", "probe-session-state.py")

spec = importlib.util.spec_from_file_location("probe_session_state", PROBE_PATH)
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)

OWNER_LINE = re.compile(r"^\s*pid (\d+)\(([^)]*)\): \[[^\]]*\] \S+ (\w+) named:")
CREATED_FOR = re.compile(r"^\s*Created for PID: (\d+)")
TOTAL_LINE = re.compile(r"^\s{3}(\w+)\s+(\d+)\s*$")


def process_name(pid):
    out, error = probe.run(["/bin/ps", "-o", "comm=", "-p", str(pid)])
    if error or not out.strip():
        return "exited"
    return os.path.basename(out.strip())


def assertions():
    out, error = probe.run(["/usr/bin/pmset", "-g", "assertions"])
    if error:
        return {"error": error}
    totals, owners = {}, []
    section = None
    for line in out.splitlines():
        if line.startswith("Assertion status system-wide"):
            section = "totals"
            continue
        if line.startswith("Listed by owning process"):
            section = "owners"
            continue
        if line.startswith("Kernel Assertions"):
            section = None
            continue
        if section == "totals":
            match = TOTAL_LINE.match(line)
            if match and match[2] != "0":
                totals[match[1]] = int(match[2])
        elif section == "owners":
            match = OWNER_LINE.match(line)
            if match:
                owners.append({"process": match[2], "type": match[3]})
                continue
            match = CREATED_FOR.match(line)
            if match and owners:
                owners[-1]["createdFor"] = process_name(match[1])
    return {"activeTotals": totals, "owners": owners}


def recorder_ancestry():
    # The recorder normally runs in a detached tmux server, so this is empty.
    # If it is not, these sshd PIDs are the control channel, not test traffic.
    pids, pid = [], os.getpid()
    for _ in range(64):
        out, error = probe.run(["/bin/ps", "-o", "ppid=,comm=", "-p", str(pid)])
        if error or not out.strip():
            break
        parent, command = out.strip().split(None, 1)
        if "sshd" in os.path.basename(command):
            pids.append(pid)
        pid = int(parent)
        if pid <= 1:
            break
    return pids


def status():
    # Live summary for a person watching over SSH. Rows belonging to this
    # status connection itself are left out of the count.
    own = set(recorder_ancestry())
    record = probe.capture()
    rows = [row for row in record.get("sshProcessEvidence", {}).get("rows", [])
            if row["pid"] not in own]
    shapes = {}
    for row in rows:
        shapes[row["titleShape"]] = shapes.get(row["titleShape"], 0) + 1
    owners = sorted({f'{o["process"]}:{o["type"]}' for o in assertions().get("owners", [])})
    print(f'  Studio {record["time"][11:19]}Z  console users: '
          f'{record.get("loginAccounting", {}).get("consoleRecords")}  '
          f'screen owner: {record.get("currentConsoleOwner", {}).get("kind")}')
    print(f'  other SSH processes (not this check): {len(rows)} {shapes or ""}')
    print("  sleep blocks: " + (", ".join(owners) or "none"))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--status", action="store_true")
    parser.add_argument("--label")
    parser.add_argument("--out")
    parser.add_argument("--interval", type=float, default=5)
    parser.add_argument("--max-hours", type=float, default=3)
    args = parser.parse_args()
    if args.status:
        return status()
    if not args.label or not args.out:
        parser.error("--label and --out are required when recording")
    if not 1 <= args.interval <= 60 or not 0 < args.max_hours <= 6:
        parser.error("interval must be 1..60 seconds; max-hours must be up to 6")

    stopping = []
    signal.signal(signal.SIGTERM, lambda *_: stopping.append(True))
    signal.signal(signal.SIGHUP, lambda *_: stopping.append(True))

    deadline = time.monotonic() + args.max_hours * 3600
    with open(args.out, "a", encoding="utf-8") as stream:
        def write(record):
            stream.write(json.dumps(record, sort_keys=True) + "\n")
            stream.flush()

        write({"kind": "header", "label": args.label,
               "time": datetime.now(timezone.utc).isoformat(),
               "intervalSeconds": args.interval, "maxHours": args.max_hours,
               "recorderSSHDAncestors": recorder_ancestry()})
        while not stopping and time.monotonic() < deadline:
            record = probe.capture()
            record["kind"] = "sample"
            record["powerAssertions"] = assertions()
            write(record)
            end = time.monotonic() + args.interval
            while not stopping and time.monotonic() < end:
                time.sleep(0.25)
        write({"kind": "footer", "time": datetime.now(timezone.utc).isoformat(),
               "reason": "stopped" if stopping else "max-hours"})
    return 0


if __name__ == "__main__":
    sys.exit(main())

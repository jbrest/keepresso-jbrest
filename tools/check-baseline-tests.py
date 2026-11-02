#!/usr/bin/env python3
"""Compare saved `swift test list` outputs. Test execution is checked separately."""
from pathlib import Path
import sys


def identities(path):
    entries = Path(path).read_text().splitlines()
    if not entries or any(not entry.strip() for entry in entries):
        raise ValueError(f"Empty identity list or blank identity: {path}")
    if len(entries) != len(set(entries)):
        raise ValueError(f"Duplicate test identities: {path}")
    return set(entries)


def main():
    if len(sys.argv) != 3:
        print("Usage: check-baseline-tests.py BASELINE_LIST CURRENT_LIST", file=sys.stderr)
        return 2
    try:
        baseline, current = (identities(path) for path in sys.argv[1:])
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    missing = baseline - current
    if missing:
        print("Missing baseline test identities:\n" + "\n".join(sorted(missing)), file=sys.stderr)
        return 1
    print(f"All {len(baseline)} baseline test identities retained; {len(current - baseline)} additional tests")
    return 0


if __name__ == "__main__":
    sys.exit(main())

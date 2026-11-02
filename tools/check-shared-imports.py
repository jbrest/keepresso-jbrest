#!/usr/bin/env python3
"""Check shared-module import allowlists; SwiftPM owns project dependencies.

Deliberately conservative, line-based check. SDK framework imports are available
without SwiftPM dependencies, so check them as well as product imports here.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {
    "RuleModel": {"Foundation"},
    "RuleEvaluation": {"Foundation", "RuleModel"},
    "SystemObservations": {"Foundation", "RuleModel", "IOKit", "Darwin", "SystemConfiguration"},
    "PowerControl": {"Foundation", "IOKit", "Darwin"},
    "ServiceSupport": {"Foundation", "Security", "ServiceManagement", "Darwin"},
}
IMPORT = re.compile(
    r"^\s*(?:(?:@\w+(?:\([^)]*\))?|public|internal|private|fileprivate|package)\s+)*"
    r"import\s+(?:(?:typealias|struct|class|enum|protocol|let|var|func)\s+)?(\w+)"
)


def main():
    failures = []
    files = sorted((ROOT / "Sources/Shared").rglob("*.swift"))
    if not files:
        print("No shared Swift sources found", file=sys.stderr)
        return 1
    for path in files:
        module = path.relative_to(ROOT / "Sources/Shared").parts[0]
        if module not in ALLOWED:
            failures.append(f"{path.relative_to(ROOT)}: unreviewed shared module {module}")
            continue
        with path.open() as source:
            for number, line in enumerate(source, 1):
                match = IMPORT.match(line)
                if match and match[1] not in ALLOWED[module]:
                    failures.append(f"{path.relative_to(ROOT)}:{number}: {module} cannot import {match[1]}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print(f"Shared import check passed ({len(files)} Swift files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

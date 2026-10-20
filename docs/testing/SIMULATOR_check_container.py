"""Find UI-test sentinel keys in an App's ordinary simulator data files.

This is a narrow leakage check, not a proof that all storage or transport is safe.
Only filenames and match counts are emitted; file contents are never printed.
"""

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("container", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    sentinel = b"UITEST_INVALID_KEY_"
    scanned = 0
    unreadable = []
    matches = []
    for path in args.container.rglob("*"):
        if not path.is_file():
            continue
        try:
            contents = path.read_bytes()
            scanned += 1
            count = contents.count(sentinel)
            if count:
                matches.append({"path": str(path.relative_to(args.container)), "matches": count})
        except OSError:
            unreadable.append(str(path.relative_to(args.container)))
    report = {
        "check": "UI-test sentinel key in ordinary App data container",
        "files_scanned": scanned,
        "matching_files": matches,
        "unreadable_files": unreadable,
        "result": "FAIL" if matches else "PASS" if scanned and not unreadable else "INCOMPLETE",
        "limits": "Only the known invalid UI-test sentinel is searched; Keychain and network are outside this check.",
    }
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 1 if matches or not scanned or unreadable else 0


if __name__ == "__main__":
    raise SystemExit(main())

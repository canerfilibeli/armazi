#!/usr/bin/env python3
"""Keep EmbeddedBenchmarks.swift in sync with the benchmark YAML sources.

The YAML files under Sources/ArmaziCore/Benchmarks/ are the source of truth for
contributors; the same text is compiled into the binary as a raw string literal
so a downloaded release needs no resource bundle. This script regenerates those
literals, or verifies they match.

    python3 Scripts/sync-embedded-benchmarks.py           # rewrite the literals
    python3 Scripts/sync-embedded-benchmarks.py --check   # fail if they drifted
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SWIFT_FILE = ROOT / "Sources/ArmaziCore/Engine/EmbeddedBenchmarks.swift"
BENCHMARKS = {
    "cisMacOS": ROOT / "Sources/ArmaziCore/Benchmarks/cis-macos-benchmark.yaml",
    "personalProtection": ROOT / "Sources/ArmaziCore/Benchmarks/personal-protection-benchmark.yaml",
}

BLOCK = re.compile(r'(static let (\w+): String = #"""\n)(.*?)(\n"""#)', re.S)


def main() -> int:
    check_only = "--check" in sys.argv
    source = SWIFT_FILE.read_text()
    found = {name for _, name, _, _ in BLOCK.findall(source)}

    missing = set(BENCHMARKS) - found
    if missing:
        print(f"error: no embedded literal for {', '.join(sorted(missing))}", file=sys.stderr)
        return 1

    drifted = []

    def replace(match: "re.Match[str]") -> str:
        head, name, body, tail = match.groups()
        path = BENCHMARKS.get(name)
        if path is None:
            return match.group(0)
        yaml = path.read_text().rstrip("\n")
        if '"""#' in yaml or "\\#" in yaml:
            raise SystemExit(f"error: {path.name} contains a Swift raw-string delimiter")
        if yaml != body:
            drifted.append(path.relative_to(ROOT))
        return head + yaml + tail

    updated = BLOCK.sub(replace, source)

    if not drifted:
        print("embedded benchmarks are in sync")
        return 0

    names = ", ".join(str(p) for p in drifted)
    if check_only:
        print(f"error: embedded literals are out of date for {names}", file=sys.stderr)
        print("run: python3 Scripts/sync-embedded-benchmarks.py", file=sys.stderr)
        return 1

    SWIFT_FILE.write_text(updated)
    print(f"updated embedded literals for {names}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

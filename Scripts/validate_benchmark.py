#!/usr/bin/env python3
"""Validate benchmark YAML files before they reach the Swift parser.

Checks that every benchmark in Sources/ArmaziCore/Benchmarks/ (or the files
given on the command line):

  * parses as YAML and has the required top-level keys
  * has unique, non-empty check IDs
  * uses a known category, framework and match rule type
  * has an audit command that is valid POSIX shell (`sh -n`)

    python3 Scripts/validate_benchmark.py
    python3 Scripts/validate_benchmark.py path/to/benchmark.yaml

Requires PyYAML (`pip3 install pyyaml`).
"""

import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("error: PyYAML is required — install it with: pip3 install pyyaml")

ROOT = Path(__file__).resolve().parent.parent
BENCHMARK_DIR = ROOT / "Sources/ArmaziCore/Benchmarks"

# Keep in sync with CheckCategory.swift and ComplianceFramework.swift.
CATEGORIES = {
    "access_security",
    "firewall_sharing",
    "updates",
    "system_integrity",
    "identity_protection",
    "data_protection",
    "privacy",
    "network_protection",
}
FRAMEWORKS = {"cis", "iso", "nist-csf", "essentials", "soc"}
MATCH_TYPES = {"contains", "not_contains", "equals", "regex", "exit_code"}
TOP_LEVEL_KEYS = {"name", "version", "platform", "description", "checks"}
REQUIRED_CHECK_KEYS = {"id", "title", "description", "category", "level", "scored", "audit", "frameworks"}


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    document = yaml.safe_load(path.read_text())

    if not isinstance(document, dict):
        return [f"{path.name}: top level is not a mapping"]

    for key in sorted(TOP_LEVEL_KEYS - document.keys()):
        errors.append(f"{path.name}: missing top-level key '{key}'")

    checks = document.get("checks") or []
    if not checks:
        errors.append(f"{path.name}: no checks defined")

    seen: set[str] = set()
    for index, check in enumerate(checks):
        check_id = check.get("id", f"<check {index}>")
        where = f"{path.name} [{check_id}]"

        for key in sorted(REQUIRED_CHECK_KEYS - check.keys()):
            errors.append(f"{where}: missing key '{key}'")

        if check_id in seen:
            errors.append(f"{where}: duplicate check ID")
        seen.add(check_id)

        category = check.get("category")
        if category not in CATEGORIES:
            errors.append(f"{where}: unknown category '{category}'")

        for framework in check.get("frameworks") or []:
            if framework not in FRAMEWORKS:
                errors.append(f"{where}: unknown framework '{framework}'")

        if check.get("level") not in (1, 2):
            errors.append(f"{where}: level must be 1 or 2, got {check.get('level')!r}")

        if not isinstance(check.get("scored"), bool):
            errors.append(f"{where}: 'scored' must be a boolean")

        if "elevated" in check and not isinstance(check["elevated"], bool):
            errors.append(f"{where}: 'elevated' must be a boolean")

        audit = check.get("audit") or {}
        command = audit.get("command")
        match = audit.get("match") or {}

        if not command:
            errors.append(f"{where}: audit command is empty")
        else:
            syntax = subprocess.run(
                ["sh", "-n"], input=command, text=True, capture_output=True
            )
            if syntax.returncode != 0:
                errors.append(f"{where}: audit command is not valid shell: {syntax.stderr.strip()}")

        if match.get("type") not in MATCH_TYPES:
            errors.append(f"{where}: unknown match type '{match.get('type')}'")
        if not str(match.get("value", "")):
            errors.append(f"{where}: match value is empty")

        # A check whose output is matched on "PASS" must be able to emit it.
        if match.get("type") == "contains" and match.get("value") == "PASS" and command:
            if "PASS" not in command:
                errors.append(f"{where}: matches on 'PASS' but never emits it")

    return errors


def main() -> int:
    paths = [Path(arg) for arg in sys.argv[1:]] or sorted(BENCHMARK_DIR.glob("*.yaml"))
    if not paths:
        sys.exit(f"error: no benchmark files found in {BENCHMARK_DIR}")

    errors: list[str] = []
    for path in paths:
        errors.extend(validate(path))
        document = yaml.safe_load(path.read_text()) or {}
        print(f"{path.name}: {len(document.get('checks') or [])} checks")

    if errors:
        print()
        for error in errors:
            print(f"  ✗ {error}")
        print(f"\n{len(errors)} problem(s) found.")
        return 1

    print("\nAll benchmarks valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

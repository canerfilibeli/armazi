#!/usr/bin/env python3
"""Validate every benchmark YAML in Sources/ArmaziCore/Benchmarks.

Checks the things the Swift decoder and the shell runner care about:

  * required keys are present and correctly typed
  * category / framework / match values are ones the models can decode
  * check IDs are unique inside a file
  * audit commands are valid /bin/sh syntax (sh -n), since that is the
    shell ShellExecutor runs them with
  * commands matching on a literal token (PASS, enabled, …) can actually
    emit it

Usage: Scripts/validate-benchmarks.py [path ...]
"""

import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip3 install pyyaml")

ROOT = Path(__file__).resolve().parent.parent
BENCHMARK_DIR = ROOT / "Sources" / "ArmaziCore" / "Benchmarks"

# Mirrors CheckCategory.swift
CATEGORIES = {
    "access_security",
    "firewall_sharing",
    "updates",
    "system_integrity",
    "identity_protection",
    "data_protection",
    "online_safety",
    "home_network",
    "privacy",
}

# Mirrors ComplianceFramework.swift
FRAMEWORKS = {"cis", "iso", "nist-csf", "essentials", "soc"}

# Mirrors MatchRule.swift
MATCH_TYPES = {"contains", "not_contains", "equals", "regex", "exit_code"}

REQUIRED_BENCHMARK_KEYS = {"name", "version", "platform", "description", "checks"}
REQUIRED_CHECK_KEYS = {"id", "title", "description", "category", "level", "scored", "audit", "frameworks"}


def validate_file(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        doc = yaml.safe_load(path.read_text())
    except yaml.YAMLError as exc:
        return [f"{path.name}: YAML parse error: {exc}"]

    missing = REQUIRED_BENCHMARK_KEYS - set(doc or {})
    if missing:
        errors.append(f"{path.name}: missing top-level key(s): {', '.join(sorted(missing))}")
        return errors

    seen_ids: set[str] = set()
    for index, check in enumerate(doc["checks"]):
        label = f"{path.name}[{check.get('id', index)}]"

        missing = REQUIRED_CHECK_KEYS - set(check)
        if missing:
            errors.append(f"{label}: missing key(s): {', '.join(sorted(missing))}")
            continue

        if check["id"] in seen_ids:
            errors.append(f"{label}: duplicate check ID")
        seen_ids.add(check["id"])

        if check["category"] not in CATEGORIES:
            errors.append(f"{label}: unknown category '{check['category']}'")

        for framework in check["frameworks"]:
            if framework not in FRAMEWORKS:
                errors.append(f"{label}: unknown framework '{framework}'")

        if not isinstance(check["level"], int) or check["level"] < 1:
            errors.append(f"{label}: level must be an integer >= 1")

        if not isinstance(check["scored"], bool):
            errors.append(f"{label}: scored must be a boolean")

        if "elevated" in check and not isinstance(check["elevated"], bool):
            errors.append(f"{label}: elevated must be a boolean")

        match = check["audit"].get("match", {})
        match_type = match.get("type")
        if match_type not in MATCH_TYPES:
            errors.append(f"{label}: unknown match type '{match_type}'")
        if "value" not in match:
            errors.append(f"{label}: match is missing a value")

        command = check["audit"].get("command", "")
        if not command.strip():
            errors.append(f"{label}: audit command is empty")
            continue

        syntax = subprocess.run(
            ["/bin/sh", "-n"], input=command, text=True, capture_output=True
        )
        if syntax.returncode != 0:
            errors.append(f"{label}: shell syntax error: {syntax.stderr.strip()}")

        # Scripts that report their own verdict with echo must be able to
        # print the token the match rule looks for. One-liners matching on
        # a tool's own output (fdesetup, spctl, …) are exempt, as are
        # regex and exit-code matches.
        if match_type == "contains" and "echo" in command and match.get("value") not in command:
            errors.append(
                f"{label}: script echoes a verdict but never the matched value '{match['value']}'"
            )

    return errors


def main() -> int:
    paths = [Path(p) for p in sys.argv[1:]] or sorted(BENCHMARK_DIR.glob("*.yaml"))
    if not paths:
        print(f"No benchmark files found in {BENCHMARK_DIR}")
        return 1

    all_errors: list[str] = []
    for path in paths:
        errors = validate_file(path)
        checks = len(yaml.safe_load(path.read_text()).get("checks", []))
        status = "FAIL" if errors else "ok"
        print(f"  {status:4}  {path.name} ({checks} checks)")
        all_errors.extend(errors)

    if all_errors:
        print()
        for error in all_errors:
            print(f"  error: {error}")
        return 1

    print("\nAll benchmarks valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

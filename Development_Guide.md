# Armazi — Development Guide

## Project overview

Armazi is an open-source macOS security auditor. It reads benchmark YAML files that define security checks (audit command + expected result), runs them against the system, and reports compliance status via a SwiftUI GUI or CLI.

## Architecture

- **ArmaziCore** (library target): Models, benchmark YAML parser (Yams), check runner, shell executor. Shared engine used by both GUI and CLI.
- **Armazi** (executable target): SwiftUI macOS application. Views, ViewModels, app entry point.
- **armazi-cli** (executable target): Command-line interface using swift-argument-parser. Subcommands: `scan`, `status`, `list`.

## Build & run

```bash
swift build              # build all targets
swift run Armazi          # launch the GUI app
swift run armazi-cli      # run CLI (defaults to scan)
swift run armazi-cli status   # quick status
swift run armazi-cli list     # list all checks
swift test                # run tests (requires Xcode)
```

## Key conventions

- **Swift 5 language mode** via `swiftSettings` in Package.swift (avoids strict concurrency pain while using Swift 6 toolchain)
- **macOS 14+ (Sonoma)** minimum deployment target
- All model types are `Sendable` and `Codable`
- Shell commands run via `ShellExecutor.run(_:)` which returns `(output, exitCode)` asynchronously
- Check definitions live in YAML files under `Sources/ArmaziCore/Benchmarks/`, not in Swift code

## Benchmark profiles

Two profiles ship with the binary, selected with `--profile` (`BenchmarkProfile` in `Models/`):

- `cis` — `Benchmarks/cis-macos-benchmark.yaml`, system hardening and compliance
- `personal` — `Benchmarks/personal-protection-macos.yaml`, everyday consumer protection

Both are embedded in the binary as raw string literals in `Engine/EmbeddedBenchmarks.swift`. **That file is generated — never edit it by hand.**

```bash
Scripts/validate-benchmarks.py    # schema + /bin/sh syntax lint
Scripts/embed-benchmarks.py       # regenerate EmbeddedBenchmarks.swift
Scripts/embed-benchmarks.py --check   # CI: fail if it is stale
```

## Adding a new check

1. Edit the benchmark YAML for the profile the check belongs to
2. Add a new entry following the existing format
3. Test the audit command manually in Terminal first
4. Run `Scripts/validate-benchmarks.py`, then `Scripts/embed-benchmarks.py`
5. The check will automatically appear in the UI after rebuild

### Writing consumer checks

Checks in the personal profile follow a few extra conventions, because a
false alarm on someone's own machine costs more than a missed finding:

- The script prints its own verdict: `PASS:`, `FAIL:`, `UNKNOWN:` (setting
  could not be read), or `MANUAL:` (cannot be determined locally). The match
  rule is `contains: "PASS"`.
- Anything that depends on data macOS protects behind Full Disk Access —
  Safari preferences above all — is `scored: false`, so an unreadable
  setting surfaces as a warning rather than a failure.
- Every check carries a `remediation` written as the exact clicks to make,
  not a policy statement.

## Match rule types

- `contains` / `not_contains` — case-insensitive substring match
- `equals` — exact string comparison (trimmed)
- `regex` — regular expression match
- `exit_code` — compare command exit code

## Testing

Tests are in `Tests/ArmaziTests/`. When adding engine tests, test against `ArmaziCore` — the library target.

## Dependencies

- [Yams](https://github.com/jpsim/Yams) — YAML parsing
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) — CLI argument parsing

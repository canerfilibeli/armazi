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

## Adding a new check

1. Edit `Sources/ArmaziCore/Benchmarks/cis-macos-benchmark.yaml`
2. Add a new entry following the existing format
3. Test the audit command manually in Terminal first
4. Validate the file: `python3 Scripts/validate_benchmark.py`
5. Regenerate the embedded copy: `python3 Scripts/embed_benchmarks.py`
6. The check will automatically appear in the UI after rebuild

Audit scripts should degrade gracefully: when a setting cannot be read (a
missing plist, a TCC restriction, hardware that does not exist), print a
`WARNING:` line rather than a false `FAIL`. Use `scored: false` for checks whose
result depends on user preference or on Full Disk Access.

## Categories

`CheckCategory` in `Sources/ArmaziCore/Models/CheckCategory.swift` is the single
source of truth for category values, display names, icons and colors. The CLI
and the GUI both iterate `CheckCategory.allCases` and skip categories with no
checks, so adding a case is enough for it to appear everywhere. Keep the
`CATEGORIES` set in `Scripts/validate_benchmark.py` in sync.

## Scripts

- `Scripts/embed_benchmarks.py` — regenerates
  `Sources/ArmaziCore/Engine/EmbeddedBenchmarks.swift` from the benchmark YAML
  so the binary stays self-contained. `--check` verifies the two are in sync and
  runs in CI; stdlib only.
- `Scripts/validate_benchmark.py` — validates benchmark YAML before the Swift
  parser sees it: required keys, unique IDs, known categories, frameworks and
  match types, and `sh -n` syntax checking of every audit command. Requires
  PyYAML.

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

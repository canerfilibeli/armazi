# Armazi — Development Guide

## Project overview

Armazi is an open-source macOS security auditor. It reads benchmark YAML files that define security checks (audit command + expected result), runs them against the system, and reports compliance status via a SwiftUI GUI.

## Architecture

- **ArmaziCore** (library target): Models, benchmark YAML parser (Yams), check runner, shell executor. This is the shared engine — both the GUI app and future CLI will depend on it.
- **Armazi** (executable target): SwiftUI macOS application. Views, ViewModels, app entry point.

## Build & run

```bash
swift build          # build both targets
swift run Armazi     # launch the GUI app
swift test           # run tests
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
4. The check will automatically appear in the UI after rebuild

## Match rule types

- `contains` / `not_contains` — case-insensitive substring match
- `equals` — exact string comparison (trimmed)
- `regex` — regular expression match
- `exit_code` — compare command exit code

## Testing

Tests are in `Tests/ArmaziTests/`. When adding engine tests, test against `ArmaziCore` — the library target.

## Dependencies

- [Yams](https://github.com/jpsim/Yams) — YAML parsing

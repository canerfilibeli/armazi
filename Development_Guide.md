# Armazi — Development Guide

## Project overview

Armazi is an open-source macOS security auditor. It reads benchmark YAML files that define security checks (audit command + expected result), runs them against the system, and reports compliance status via a SwiftUI GUI or CLI.

Two benchmarks ship in the binary, selected with `--profile`:

- **`cis`** (default) — system hardening against the CIS macOS Benchmark
- **`personal`** — a consumer check-up covering identity, devices, data, online safety, the home network, privacy, and incident readiness (see `docs/PERSONAL_PROTECTION.md`)

## Architecture

- **ArmaziCore** (library target): Models, benchmark YAML parser (Yams), check runner, shell executor. Shared engine used by both GUI and CLI.
- **Armazi** (executable target): SwiftUI macOS application. Views, ViewModels, app entry point.
- **armazi-cli** (executable target): Command-line interface using swift-argument-parser. Subcommands: `scan`, `status`, `list`.

## Build & run

```bash
swift build              # build all targets
swift run armazi scan --profile personal   # personal protection check-up
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

1. Edit the YAML for the profile you are extending:
   - `Sources/ArmaziCore/Benchmarks/cis-macos-benchmark.yaml`
   - `Sources/ArmaziCore/Benchmarks/personal-protection-benchmark.yaml`
2. Add a new entry following the existing format
3. Test the audit command manually in Terminal first
4. Run `python3 Scripts/sync-embedded-benchmarks.py` so the copy compiled into the binary matches (CI fails if it drifts)
5. The check will automatically appear in the UI after rebuild

### Conventions for the personal profile

- Match on the `ARMAZI_PASS` token, never `PASS` or `OK` — `contains` is case-insensitive and substring-based, so "PASS" matches "**pass**word" and "OK" matches "br**ok**en"
- Emit `ARMAZI_FAIL` for a real failure and `ARMAZI_REVIEW` when the check could not determine the answer
- Do not set `elevated: true` — the personal profile runs without an administrator prompt
- If a capability cannot be observed from the machine (a carrier PIN, a broker opt-out), make it an *attested* check that reads `~/.config/armazi/attested.txt`, rather than a check that always fails or always passes

## Adding a profile

1. Add the YAML under `Sources/ArmaziCore/Benchmarks/`
2. Add a case to `BenchmarkProfile` (`Sources/ArmaziCore/Models/BenchmarkProfile.swift`) with its `fileName` and `embeddedYAML`
3. Add the file to `BENCHMARKS` in `Scripts/sync-embedded-benchmarks.py` and run it
4. Add any new `CheckCategory` cases — the CLI and GUI iterate `allCases` and skip empty categories, so nothing else needs updating

## Match rule types

- `contains` / `not_contains` — case-insensitive substring match
- `equals` — exact string comparison (trimmed)
- `regex` — regular expression match
- `exit_code` — compare command exit code

## Testing

Tests are in `Tests/ArmaziTests/`. When adding engine tests, test against `ArmaziCore` — the library target.

Benchmark tests parse `BenchmarkProfile.<case>.embeddedYAML` directly rather than calling `loadBundled(profile:)`, so a local override in `~/.config/armazi/benchmarks/` cannot change the result.

## Dependencies

- [Yams](https://github.com/jpsim/Yams) — YAML parsing
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) — CLI argument parsing

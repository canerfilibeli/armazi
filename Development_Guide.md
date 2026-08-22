# Armazi — Development Guide

## Project overview

Armazi is an open-source macOS security auditor. It reads benchmark YAML files that define security checks (audit command + expected result), runs them against the system, and reports compliance status via a SwiftUI GUI or CLI.

## Architecture

- **ArmaziCore** (library target): Models, benchmark YAML parser (Yams), check runner, shell executor. Shared engine used by both GUI and CLI.
- **ArmaziApp** (executable target): SwiftUI macOS application. Views, ViewModels, app entry point.
- **armazi** (executable target): Command-line interface using swift-argument-parser. Subcommands: `scan`, `status`, `list`, `update`, `update-benchmarks`, `import`.

## Build & run

```bash
swift build                          # build all targets
swift run ArmaziApp                  # launch the GUI app
swift run armazi                     # run CLI (defaults to scan)
swift run armazi status              # quick status
swift run armazi list                # list all checks
swift run armazi scan --profile all  # both benchmark profiles in one report
swift test                           # run tests (requires Xcode)
```

## Key conventions

- **Swift 5 language mode** via `swiftSettings` in Package.swift (avoids strict concurrency pain while using Swift 6 toolchain)
- **macOS 14+ (Sonoma)** minimum deployment target
- All model types are `Sendable` and `Codable`
- Shell commands run via `ShellExecutor.run(_:)` which returns `(output, exitCode)` asynchronously
- Check definitions live in YAML files under `Sources/ArmaziCore/Benchmarks/`, not in Swift code

## Benchmark profiles

Two benchmarks ship in the binary, selected with `--profile` (CLI) or the
toolbar picker (GUI):

| Profile | File | Focus |
|---|---|---|
| `cis` (default) | `cis-macos-benchmark.yaml` | System hardening |
| `personal` | `personal-macos-benchmark.yaml` | Identity, backups, browsing, home network, privacy |
| `all` | both, merged | Everything |

`BenchmarkRegistry.load(profile:)` resolves a profile: a local override in
`~/.config/armazi/benchmarks/` wins over the copy embedded in the binary.
`merge(_:name:description:)` combines definitions, keeping the first occurrence
of any duplicated check ID — so the two profiles must not share IDs (a test
enforces this).

## Adding a new check

1. Edit the YAML for the profile the check belongs to in
   `Sources/ArmaziCore/Benchmarks/`
2. Add a new entry following the existing format
3. Test the audit command manually in Terminal first — commands run under
   `/bin/sh`, so keep them POSIX (no `[[ ]]`, no arrays)
4. Run `./Scripts/embed-benchmarks.sh` to regenerate `EmbeddedBenchmarks.swift`
5. The check will automatically appear in the UI after rebuild

Elevated checks (`elevated: true`) are concatenated into a single batch script so
macOS prompts for a password once. A command in an elevated check must never call
`exit` — it would terminate the batch and drop every check after it.

Personal-profile checks often read sandboxed preference domains or optional
tooling. When an audit cannot determine the answer, print `UNKNOWN: ...` and mark
the check `scored: false`, so it reports as a warning to review instead of a
false failure.

## Adding a new category

`CheckCategory` is an enum in `Sources/ArmaziCore/Models/CheckCategory.swift`.
Add the case, its `rawValue` (matching the YAML `category:` field), display name,
SF Symbol, and color. The CLI and GUI iterate `allCases` and skip categories with
no checks, so nothing else needs to change.

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

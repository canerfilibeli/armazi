# Armazi

**Open-source macOS security auditor** — scan your Mac against CIS Benchmarks and industry compliance frameworks.

> **Armazi** (არმაზი) is the chief guardian deity of ancient Colchian and Georgian mythology. His statue stood at the gates of Mtskheta, the capital of the Kingdom of Iberia, watching over all who entered. Like its namesake, Armazi stands guard at the gates of your macOS system — scanning, auditing, and reporting security configurations to keep your machine safe.

## What it does

Armazi reads a **benchmark definition file** (YAML) that describes security checks — each with an audit command, expected result, and remediation steps. It runs those checks against your system and produces a compliance report.

Ships with a built-in **CIS macOS Benchmark** covering 27 checks across four categories:

| Category | Checks | Examples |
|---|---|---|
| **Access Security** | 9 | Auto login, screen lock, SSH key strength |
| **Firewall & Sharing** | 9 | Firewall status, AirDrop, Remote Login |
| **macOS Updates** | 3 | Auto updates, App Store updates |
| **System Integrity** | 6 | FileVault, Gatekeeper, Secure Boot |

### Compliance Frameworks

Each check is mapped to one or more compliance frameworks:

- **CIS** — CIS Critical Security Controls
- **ISO** — ISO 27001
- **NIST CSF** — NIST Cybersecurity Framework
- **Essentials** — Cyber Essentials (UK)
- **SOC** — System and Organization Controls

## Architecture

```
Sources/
├── ArmaziCore/          # Shared library (benchmark engine)
│   ├── Models/          # CheckDefinition, CheckResult, ScanReport, etc.
│   ├── Engine/          # BenchmarkParser (YAML), CheckRunner, ShellExecutor
│   └── Benchmarks/      # Bundled YAML benchmark files
├── ArmaziCLI/           # Command-line interface (scan, status, list)
│   └── Benchmarks/      # Bundled YAML benchmark files
└── Armazi/              # SwiftUI macOS application
    ├── Views/           # Dashboard, category detail, report views
    └── ViewModels/      # DashboardViewModel
```

The engine is in `ArmaziCore` — a standalone library that can be used by both the GUI app and a future CLI tool.

## Custom Benchmarks

You can create your own benchmark YAML files. Each check defines:

```yaml
- id: "1.1"
  title: "Automatic Login is off"
  description: "Prevent unauthorized access."
  category: "access_security"
  level: 1
  scored: true
  audit:
    command: "defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>&1"
    match:
      type: "contains"
      value: "does not exist"
  remediation: "sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser"
  frameworks: ["cis", "iso", "nist-csf"]
```

### Match rules

| Type | Description |
|---|---|
| `contains` | Output contains the value |
| `not_contains` | Output does not contain the value |
| `equals` | Output exactly equals the value |
| `regex` | Output matches the regular expression |
| `exit_code` | Command exit code equals the value |

## CLI

Armazi also ships as a command-line tool:

```bash
swift run armazi-cli              # run a full scan (default)
swift run armazi-cli status       # quick status summary
swift run armazi-cli list         # list all checks
swift run armazi-cli scan -v      # verbose scan with remediation steps
swift run armazi-cli scan --json  # JSON output (for CI/CD)
swift run armazi-cli scan --watch # re-run checks periodically
swift run armazi-cli scan --check 2.4  # run a single check
swift run armazi-cli scan --category firewall_sharing  # scan one category
```

Exit code is non-zero when any check fails — useful in CI pipelines.

## Building

Requires macOS 14+ and Swift 6.0+.

```bash
swift build
swift run Armazi         # GUI app
swift run armazi-cli     # CLI tool
```

## Contributing

Contributions are welcome. The easiest way to contribute is by adding or improving checks in the benchmark YAML file — no Swift knowledge required.

See [Development_Guide.md](Development_Guide.md) for development guidelines.

## License

MIT License. See [LICENSE](LICENSE).

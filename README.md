# Armazi

**Open-source macOS security auditor** — scan your Mac against CIS Benchmarks and industry compliance frameworks.

> **Armazi** (არმაზი) is the chief guardian deity of ancient Colchian and Georgian mythology. His statue stood at the gates of Mtskheta, the capital of the Kingdom of Iberia, watching over all who entered. Like its namesake, Armazi stands guard at the gates of your macOS system — scanning, auditing, and reporting security configurations to keep your machine safe.

---

## Install

### Homebrew (recommended)

```bash
brew tap canerfilibeli/tap
brew install armazi
```

### Direct download

```bash
curl -L -o armazi https://github.com/canerfilibeli/armazi/releases/latest/download/armazi-macos-arm64
chmod +x armazi
sudo mv armazi /usr/local/bin/
```

### Build from source

Requires macOS 14+ and Swift 6.0+.

```bash
git clone https://github.com/canerfilibeli/armazi.git
cd armazi
swift build -c release --product armazi
sudo cp .build/release/armazi /usr/local/bin/
```

---

## Quick Start

```bash
armazi                # run a full scan (default command)
armazi status         # one-line security summary
```

---

## CLI Commands

### `armazi scan`

Run all security checks against your system.

```bash
armazi scan                  # full scan with colored output
armazi scan --verbose        # include remediation steps for each failure
armazi scan --json           # output results as JSON (for CI/CD pipelines)
armazi scan --level 2        # use CIS Level 2 profile (stricter)
```

**Filter by category:**

```bash
armazi scan --category access_security
armazi scan --category firewall_sharing
armazi scan --category updates
armazi scan --category system_integrity
```

**Run a single check:**

```bash
armazi scan --check 2.4      # only check if firewall is enabled
armazi scan --check 4.2      # only check FileVault status
```

**Watch mode** — re-run checks on an interval and highlight changes:

```bash
armazi scan --watch                # re-scan every 60 seconds
armazi scan --watch --interval 30  # re-scan every 30 seconds
```

**Skip the update check on startup:**

```bash
armazi scan --skip-update
```

Exit code is **non-zero** when any scored check fails — useful in CI pipelines.

---

### `armazi status`

Quick one-line summary showing your score and category breakdown.

```bash
armazi status
armazi status --level 2
```

Example output:

```
Armazi Security Status

66% — 18 passed, 7 failed out of 27 checks

○ Access Security        7/9
○ Firewall & Sharing     8/9
○ macOS Updates          1/3
○ System Integrity       2/6
```

---

### `armazi list`

List all checks in the loaded benchmark without running them.

```bash
armazi list                          # list all Level 1 checks
armazi list --level 2                # include Level 2 checks
armazi list --benchmark custom.yaml  # list checks from a custom file
```

---

### `armazi update`

Check for a new version and install it.

```bash
armazi update
```

Downloads are verified with SHA-256 checksums before installation.

---

### `armazi update-benchmarks`

Download the latest benchmark YAML files from GitHub without updating the binary.

```bash
armazi update-benchmarks
```

Benchmarks are saved to `~/.config/armazi/benchmarks/` and automatically used on the next scan.

---

### `armazi import`

Convert a CIS XCCDF (XML) benchmark file to Armazi's YAML format.

```bash
armazi import CIS_Apple_macOS_14.0_Benchmark_v2.0.0-xccdf.xml
armazi import benchmark.xml --output my-benchmark.yaml
armazi import benchmark.xml --name "My Custom Benchmark"
armazi import benchmark.xml --install   # convert and install for immediate use
```

---

## What It Checks

Ships with a built-in **CIS macOS Benchmark** covering 27 checks across four categories:

### Access Security (9 checks)

| Check | Description |
|---|---|
| Automatic Login is off | Prevent unauthorized access |
| No unused user accounts | Reduce attack surface |
| Not using Administrator account | Limit admin account use |
| Password after inactivity | Lock screen after idle |
| Password manager installed | Manage passwords securely |
| Password to unlock Preferences | Require admin for system changes |
| Screen Saver after 20 min | Prevent unauthorized access |
| SSH keys require a password | Protect private keys |
| SSH keys use strong encryption | Ed25519 or RSA ≥3072-bit |

### Firewall & Sharing (9 checks)

| Check | Description |
|---|---|
| AirDrop is secured | Contacts Only or disabled |
| AirPlay Receiver is off | No unauthorized streaming |
| File Sharing is off | SMB disabled |
| Firewall is on | Block unauthorized connections |
| Internet Sharing is off | Mac not acting as router |
| Media Sharing is off | Library not exposed |
| Printer Sharing is off | Reduce attack surface |
| Remote Login is off | SSH disabled |
| Remote Management is off | ARD disabled |

### macOS Updates (3 checks)

| Check | Description |
|---|---|
| App Store updates automatic | Keep apps patched |
| Application updates automatic | Auto-install app updates |
| macOS updates automatic | Receive security patches |

### System Integrity (6 checks)

| Check | Description |
|---|---|
| Boot is secure | Full Security boot policy |
| FileVault is on | Disk encryption enabled |
| Gatekeeper is on | Block non-notarized apps |
| Terminal secure keyboard entry | Prevent keystroke interception |
| Time Machine encrypted | Secure backups |
| Wi-Fi connection secure | WPA2/WPA3 encryption |

---

## Compliance Frameworks

Each check is mapped to one or more compliance frameworks:

| Framework | Full Name |
|---|---|
| **CIS** | CIS Critical Security Controls |
| **ISO** | ISO 27001 |
| **NIST CSF** | NIST Cybersecurity Framework |
| **Essentials** | Cyber Essentials (UK) |
| **SOC** | System and Organization Controls |

Use `armazi scan --json` and filter by framework for compliance reporting.

---

## Custom Benchmarks

Armazi is benchmark-driven — checks are defined in YAML, not code. You can create your own:

```yaml
name: "My Custom Benchmark"
version: "1.0.0"
platform: "macOS"
description: "Custom security checks for my organization."

checks:
  - id: "C.1"
    title: "Bluetooth is off"
    description: "Disable Bluetooth when not in use."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: "defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null"
      match:
        type: "equals"
        value: "0"
    remediation: "System Settings > Bluetooth > Turn Off"
    frameworks: ["cis"]
```

Run it with:

```bash
armazi scan --benchmark my-benchmark.yaml
```

### Match Rules

| Type | Description | Example |
|---|---|---|
| `contains` | Output contains the value (case-insensitive) | `"FileVault is On"` |
| `not_contains` | Output does not contain the value | `"FAIL"` |
| `equals` | Output exactly matches (trimmed) | `"0"` |
| `regex` | Output matches a regular expression | `"enabled\|on"` |
| `exit_code` | Command exit code equals the value | `"0"` |

### Elevated Checks

Add `elevated: true` to checks that require admin privileges. All elevated checks are batched into a single password prompt:

```yaml
  - id: "2.4"
    title: "Firewall is on"
    elevated: true
    audit:
      command: "/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate"
      match:
        type: "contains"
        value: "enabled"
```

---

## Benchmark Loading Priority

1. **Custom file** — `armazi scan --benchmark path/to/file.yaml`
2. **Local overrides** — `~/.config/armazi/benchmarks/cis-macos-benchmark.yaml`
3. **Built-in default** — embedded in the binary, always available

Use `armazi update-benchmarks` to pull the latest from GitHub into the local overrides directory.

---

## Architecture

```
Sources/
├── ArmaziCore/          # Shared library
│   ├── Models/          # CheckDefinition, CheckResult, ScanReport
│   ├── Engine/          # BenchmarkParser, CheckRunner, ShellExecutor,
│   │                    # SelfUpdater, BenchmarkUpdater, XCCDFImporter
│   └── Benchmarks/      # Source YAML files
├── ArmaziCLI/           # CLI (scan, status, list, update, import)
└── Armazi/              # SwiftUI macOS GUI application
    ├── Views/           # Dashboard, category detail, report, score ring
    └── ViewModels/      # DashboardViewModel
```

`ArmaziCore` is a standalone library used by both the CLI and the GUI app.

---

## Security

Armazi takes security seriously:

- **Checksum verification** — binary updates are verified with SHA-256
- **No silent auto-install** — update checks only notify; installation requires explicit `armazi update`
- **HTTPS enforced** — all downloads require HTTPS
- **Sanitized inputs** — check IDs are sanitized before shell interpolation
- **Secure temp files** — UUID-based paths with restrictive permissions (0700)
- **XXE protection** — XML parser has external entity resolution disabled
- **Atomic updates** — binary replacement uses atomic file swap
- **CodeQL analysis** — automated security scanning on every push and PR

To report a security vulnerability, please open an issue on GitHub.

---

## Roadmap

- [ ] **macOS .app bundle** — double-click to launch, Dock icon, notarization
- [ ] **Menu bar agent** — background process showing security score in the menu bar
- [ ] **One-click remediation** — "Fix" button in GUI that applies the recommended fix
- [ ] **PDF report export** — generate compliance reports from CLI and GUI
- [ ] **Python cross-platform CLI** — `pip install armazi` for Linux and Windows
- [ ] **Web dashboard** — centralized reporting portal for multiple machines
- [ ] **Expand macOS checks** — full CIS Benchmark coverage (100+ checks)
- [ ] **Linux benchmark YAMLs** — Ubuntu, Debian, RHEL, Fedora, SUSE
- [ ] **Windows benchmark YAMLs** — Windows 10/11 and Server
- [ ] **DISA STIG importer** — direct import from public.cyber.mil
- [ ] **Scheduled scans** — periodic scans with drift detection and notifications
- [ ] **Team dashboard** — track compliance across a fleet of machines
- [ ] **Homebrew Cask** — `brew install --cask armazi` for the GUI app

---

## Contributing

Contributions are welcome. The easiest way to contribute is by adding or improving checks in the benchmark YAML file — no Swift knowledge required.

1. Fork the repository
2. Edit `Sources/ArmaziCore/Benchmarks/cis-macos-benchmark.yaml`
3. Test the audit command in Terminal first
4. Submit a pull request

See [Development_Guide.md](Development_Guide.md) for build instructions and coding conventions.

---

## License

MIT License. See [LICENSE](LICENSE).

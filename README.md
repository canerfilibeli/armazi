# Armazi

**Open-source macOS security auditor** — scan your Mac against CIS Benchmarks and industry compliance frameworks, plus a personal security profile covering identity, backups, safe browsing, your home network, and privacy.

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
armazi                          # run a full scan (default command)
armazi status                   # one-line security summary
armazi scan --profile personal  # personal security, privacy & home network
armazi scan --profile all       # everything, in one report
```

### Profiles

Armazi ships two sets of checks. They do not overlap — run `--profile all` for both.

| Profile | What it covers |
|---|---|
| `cis` *(default)* | **System hardening** — CIS macOS Benchmark: access control, sharing services, updates, system integrity. |
| `personal` | **Personal security** — identity & accounts, backup and recovery, safe browsing, home network, privacy. |
| `all` | Both profiles merged into a single report. |

See [docs/PERSONAL_SECURITY.md](docs/PERSONAL_SECURITY.md) for how the personal
profile maps onto what people expect from a consumer security product, and where
this tool deliberately stops.

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

**Choose a profile:**

```bash
armazi scan --profile cis        # system hardening (default)
armazi scan --profile personal   # personal security, privacy & home network
armazi scan --profile all        # both
```

**Filter by category:**

```bash
armazi scan --category access_security
armazi scan --category firewall_sharing
armazi scan --category updates
armazi scan --category system_integrity

armazi scan --profile personal --category identity_protection
armazi scan --profile personal --category data_protection
armazi scan --profile personal --category online_safety
armazi scan --profile personal --category network_protection
armazi scan --profile personal --category privacy
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
armazi status --profile personal
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
armazi list --profile personal       # list the personal security checks
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

The default `cis` profile ships with a built-in **CIS macOS Benchmark** covering 27 checks across four categories:

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

## Personal Security Profile

`armazi scan --profile personal` runs a second, consumer-focused benchmark of
**33 checks** across five categories. It covers what a personal security product
is expected to handle — identity, backups, safe browsing, the home network, and
privacy — without repeating anything in the CIS profile.

### Identity & Accounts (6 checks)

| Check | Description |
|---|---|
| Authenticator app is available | Use app-based multi-factor authentication instead of SMS codes, which can be intercepted by SIM-swap attacks |
| Hardware security key is present | Hardware keys (FIDO2/WebAuthn) are phishing-resistant — a fake login page cannot replay them |
| Signed in to an Apple Account | An Apple Account is what enables Find My, iCloud Keychain, and Apple's compromised-password alerts |
| iCloud Keychain password syncing is on | Syncing passwords keeps them available across devices and turns on Apple's alerts for passwords found in known data leaks |
| Guest account is disabled | The guest account allows anyone with physical access to use the Mac without credentials |
| Password hints are disabled | Password hints leak information about your password to anyone at the login window |

### Device & Data (10 checks)

| Check | Description |
|---|---|
| Find My Mac is enabled | Find My is what makes remote locate, lock, and erase possible if the Mac is lost or stolen |
| A backup has run in the last 7 days | A backup destination that has not run recently will not get your files back after ransomware, theft, or drive failure |
| Versioned cloud storage is in use | Cloud storage with version history lets you roll individual files back after corruption, accidental deletion, or ransomware |
| Malware definitions are recent | XProtect carries Apple's malware signatures |
| Security responses install automatically | Rapid Security Responses and system data files patch actively exploited flaws between full macOS releases |
| No pending macOS updates | Reports updates macOS has already found but not installed |
| Installed apps are up to date | Third-party apps and their plugins are patched on their own schedule — Homebrew is the most common way to keep them current on macOS |
| Endpoint protection is active | Reports what is actually defending this Mac against malware — Apple's built-in XProtect, a third-party agent, or both |
| Mounted external volumes are encrypted | An unencrypted backup or scratch disk hands over every file on it if the drive is lost, and makes secure disposal impossible |
| Local snapshots are available for rollback | Time Machine local snapshots let you roll the whole system back to a point before files were encrypted or corrupted |

### Online Safety (7 checks)

| Check | Description |
|---|---|
| Safari warns about fraudulent websites | Safari's fraudulent-site warning blocks known phishing and scam pages before they load |
| Safari does not auto-open downloads | Auto-opening 'safe' downloads lets a malicious archive or disk image run its payload the moment it lands |
| Chrome Safe Browsing is on | Safe Browsing blocks known phishing, scam, and malware sites in Chrome |
| Ad and tracker blocking is in place | Most consumer malware and scams arrive through malicious ads and tracking scripts |
| A filtering DNS resolver is configured | A filtering resolver blocks malware, phishing, and tracker domains for every app on the Mac, not just the browser |
| A VPN is configured | A VPN protects traffic on public and untrusted Wi-Fi, where anyone on the same network can watch unencrypted connections |
| Remembered Wi-Fi network list is small | Every remembered network is one your Mac will re-join automatically |

### Home Network (4 checks)

| Check | Description |
|---|---|
| Router has no legacy admin services open | Telnet and FTP on a home router are unauthenticated or cleartext, and are a common way routers get taken over |
| Home network device inventory | Lists the devices your Mac can currently see on the local network, so unfamiliar ones stand out |
| No unexpected services listening on the network | Anything listening on a non-loopback address is reachable by every other device on the network, including compromised IoT devices |
| No unexpected web proxy is configured | A proxy silently inserted into your network settings can read and modify traffic — a common trait of adware and MITM tooling |

### Privacy (6 checks)

| Check | Description |
|---|---|
| Personalized ads are off | Apple's personalized advertising builds a profile from your App Store, Apple News, and Stocks activity |
| Analytics sharing with Apple is off | Diagnostic submissions can contain fragments of documents, URLs, and crash data from the apps you use |
| Siri and Dictation data sharing is off | Opting in sends audio recordings and transcripts of your requests to Apple for review |
| Location Services state is known | Location is what makes Find My work, and also what lets apps build a movement history |
| Computer name does not reveal your identity | The computer name is broadcast over AirDrop, Bonjour, and every network you join — including public Wi-Fi |
| Encrypted messaging is available | End-to-end encrypted messaging keeps conversations and shared files private in transit and on the provider's servers |

Many of these settings live in sandboxed preference domains or depend on optional
tooling. A check that cannot determine the answer reports `UNKNOWN` and surfaces
as a **warning to review** rather than a failure, so only checks with an
unambiguous system-level answer count against the score.

Full mapping of customer expectations to coverage — including what is deliberately
out of scope — is in [docs/PERSONAL_SECURITY.md](docs/PERSONAL_SECURITY.md).

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
│   ├── Models/          # CheckDefinition, CheckResult, ScanReport,
│   │                    # CheckCategory, BenchmarkProfile
│   ├── Engine/          # BenchmarkParser, BenchmarkRegistry, CheckRunner,
│   │                    # ShellExecutor, SelfUpdater, BenchmarkUpdater,
│   │                    # XCCDFImporter, EmbeddedBenchmarks (generated)
│   └── Benchmarks/      # Source YAML files — cis-macos, personal-macos
├── ArmaziCLI/           # CLI (scan, status, list, update, import)
└── Armazi/              # SwiftUI macOS GUI application
    ├── Views/           # Dashboard, category detail, report, score ring
    └── ViewModels/      # DashboardViewModel

Scripts/
└── embed-benchmarks.sh  # regenerates EmbeddedBenchmarks.swift from the YAML
```

`ArmaziCore` is a standalone library used by both the CLI and the GUI app.

Benchmarks are embedded in the binary as string literals. After editing anything
in `Sources/ArmaziCore/Benchmarks/`, run `./Scripts/embed-benchmarks.sh` to
regenerate `EmbeddedBenchmarks.swift` (`--check` verifies it is up to date).

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

Personal security profile ([details](docs/PERSONAL_SECURITY.md)):

- [x] **Personal security profile** — identity, backups, browsing, home network, privacy
- [ ] **Breach lookup** — `armazi breach` against the Have I Been Pwned range API (k-anonymity, nothing leaves the machine in the clear)
- [ ] **Weighted risk score** — a failed FileVault check should not cost the same as a missing ad blocker
- [ ] **New-device alerts** — remember the home network between scans and flag devices that appear
- [ ] **Monthly health report** — scheduled scan plus an exported summary of what changed
- [ ] **Family coverage** — multiple machines and accounts under one report
- [ ] **Incident playbook** — offline first-steps guidance for a hacked account or stolen device

---

## Contributing

Contributions are welcome. The easiest way to contribute is by adding or improving checks in the benchmark YAML file — no Swift knowledge required.

1. Fork the repository
2. Edit `Sources/ArmaziCore/Benchmarks/cis-macos-benchmark.yaml` (system hardening) or
   `personal-macos-benchmark.yaml` (personal security)
3. Test the audit command in Terminal first
4. Run `./Scripts/embed-benchmarks.sh` so the embedded copy matches
5. Submit a pull request

See [Development_Guide.md](Development_Guide.md) for build instructions and coding conventions.

---

## License

MIT License. See [LICENSE](LICENSE).

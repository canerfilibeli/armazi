# Protection Roadmap

Customers describing what they want from a personal security product ask for
one thing: **a one-stop, worry-free shield for identity, devices, data, home
network, and family — backed by real people they can call when something goes
wrong.**

Armazi is one piece of that: it is a local, open-source auditor. It tells you
whether the protections on this Mac are actually turned on and working. It does
not sell a VPN, run a password vault, or watch the dark web on your behalf.

That distinction drives every decision below:

- **Armazi verifies protection. It does not replace it.** Where macOS or a
  third-party tool already provides a control, Armazi audits its state instead
  of reimplementing it.
- **Nothing leaves the machine.** Armazi has no account, no telemetry, and no
  server. Any capability that inherently needs a backend (breach monitoring,
  data-broker removal, a support hotline) is listed here as out of scope for
  the tool, not silently faked with a local approximation.
- **Everything auditable becomes a benchmark check**, defined in YAML so users
  can read, edit, and extend it without touching Swift.

## Legend

| Status | Meaning |
|---|---|
| ✅ | Shipped — a check in the bundled benchmark |
| 🟡 | Partly covered — Armazi audits a related control, full coverage needs more work |
| 📋 | Planned — auditable locally, not implemented yet |
| 🌐 | Needs a service — cannot be done by a local auditor alone |

---

## Identity & Account Protection

| Requirement | Status | Coverage |
|---|---|---|
| Password vault (secure, cross-device, autofill) | 🟡 | `1.5` verifies a password manager is installed; the vault itself is Keychain or a third-party app |
| Keychain does not stay unlocked | ✅ | `5.1` lock on sleep, `5.2` lock after inactivity |
| Multi-factor authentication, phishing-resistant | 🟡 | `5.4` audits Touch ID enrolment; Apple Account 2FA state is not readable locally |
| Guest / unauthenticated access closed off | ✅ | `5.5` Guest account off, `1.1` automatic login off |
| Remote locate, lock and wipe | ✅ | `5.3` Find My Mac enabled |
| Dashboard of leaked or compromised accounts | 🌐 | Requires a breach-data provider (HIBP-style API) and an account model |
| Dark web monitoring (email, phone, ID, cards) | 🌐 | Same — continuous monitoring is a subscription service, not a local scan |
| SIM-swap alerts | 🌐 | Carrier-side signal, no macOS API |
| Fraud / credit monitoring | 🌐 | Bureau integration, jurisdiction-specific |

**Next:** a `--check-breaches` opt-in that queries a breach API using k-anonymity
(only a hash prefix leaves the machine) would give most of the dashboard value
with none of the account infrastructure. It stays opt-in and off by default.

## Device & Data Security

| Requirement | Status | Coverage |
|---|---|---|
| Endpoint protection (antivirus / antimalware) | ✅ | `4.3` Gatekeeper, `4.7` System Integrity Protection, `4.8` XProtect definitions current |
| Ransomware protection with rollback | ✅ | `6.3` local snapshots available for rollback, plus `4.7` |
| Encrypted backups, cloud and local | ✅ | `6.1` destination configured, `6.2` a backup ran in the last 7 days, `4.5` backups encrypted |
| Secure cloud storage with versioning | ✅ | `6.4` Desktop and Documents sync to iCloud Drive |
| Disk encryption | ✅ | `4.2` FileVault on |
| Personal files not readable by other accounts | ✅ | `6.5` home folder permissions |
| Remote wipe and locate | ✅ | `5.3` Find My Mac |
| Patch and update manager (OS *and* apps) | 🟡 | `3.1`–`3.4` cover macOS, App Store apps and security responses; third-party apps outside the App Store are not tracked |
| Secure disposal (shredding, wiping devices) | 🟡 | With FileVault on (`4.2`), erasing the volume is cryptographically sufficient; a "prepare this Mac for disposal" report is planned |

**Next:** a third-party patch report — enumerate `/Applications`, compare bundle
versions against each vendor's Sparkle appcast where one exists, and flag apps
that have not been updated in a year. Read-only, no installs.

## Online Safety

| Requirement | Status | Coverage |
|---|---|---|
| Phishing and scam protection in the browser | ✅ | `7.3` Safari fraudulent-site warnings |
| Malicious downloads not auto-opened | ✅ | `7.4` Safari does not auto-open "safe" downloads |
| Malicious site and tracker blocking at DNS level | ✅ | `8.2` DNS is not left at the router default |
| Ad blocking and privacy shielding | ✅ | `7.2` personalized advertising off, `7.1` diagnostic data not shared |
| VPN — zero-logs, split tunnelling | 🟡 | `7.5` audits that a VPN configuration exists; choosing and running a VPN is the user's provider |
| Public Wi-Fi protection | ✅ | `2.10` firewall stealth mode, `8.1` no open Wi-Fi networks remembered, `4.6` current Wi-Fi uses WPA2/WPA3 |
| Phishing protection in email, SMS, WhatsApp | 🌐 | Message content scanning needs an agent inside each app, and reading personal messages is exactly what Armazi promises not to do |
| Browser extension audit | 📋 | Installed Safari and Chrome extensions can be enumerated locally and flagged for excessive permissions |
| Safe browsing for children / family | 🌐 | Screen Time policy is per-Apple-Account; a family view needs multi-device state |

## Home & Network Protection

| Requirement | Status | Coverage |
|---|---|---|
| Home Wi-Fi hardening (weak encryption, open networks) | ✅ | `4.6`, `8.1` |
| Nothing exposed to the rest of the LAN | ✅ | `8.3` no service listens on all interfaces, plus the `2.x` sharing checks |
| IoT / wireless attack surface | 🟡 | `8.4` Bluetooth off when nothing is connected; device-level IoT posture is not visible from a Mac |
| Alert on new/unrecognized devices joining the network | 📋 | Needs a stored device inventory and scan history — see *Scheduled scans* below |
| Router hardening (default credentials, admin exposed) | 📋 | The gateway's open ports can be probed locally; credential testing will not be included |
| "Home security box" appliance | 🌐 | Hardware product, out of scope for this repository |

**Next:** scheduled scans with a stored history unlock both drift detection
("FileVault was on last week and is off today") and new-device alerts. That is
the highest-value missing capability and it needs no backend.

## Privacy & Personal Safety

| Requirement | Status | Coverage |
|---|---|---|
| Telemetry and ad profiling reduced | ✅ | `7.1`, `7.2` |
| Secure communication tools | 🟡 | `1.8`/`1.9` audit SSH key hygiene; encrypted messaging is an app choice, not a system setting |
| Data broker removal | 🌐 | A per-site opt-out service, run on the user's behalf |
| Social media privacy audit | 🌐 | Requires signing in to each platform |
| Personal digital footprint report | 🌐 | Same as above |
| Identity theft insurance and response | 🌐 | An insurance product |

## Monitoring & Support

| Requirement | Status | Coverage |
|---|---|---|
| Personal risk score | ✅ | The scan score is exactly this — a 0–100% hygiene score with a per-category breakdown |
| Monthly security health report | 🟡 | `armazi scan --json` produces the data; scheduling and PDF export are on the roadmap |
| Family add-on accounts | 🌐 | Multi-user coverage needs a fleet view |
| Fleet / team dashboard | 📋 | Already on the roadmap; JSON output is the building block |
| 24/7 hotline, breach assistance | 🌐 | Human support, not software |

## Convenience & Trust

| Requirement | Status | Coverage |
|---|---|---|
| Trusted and verifiable — not spyware | ✅ | Open source, MIT, no network calls except explicit update checks over HTTPS with SHA-256 verification |
| Clear pricing, easy cancellation, portability | ✅ | Free; benchmarks are plain YAML you can take elsewhere |
| Invisible background protection, low friction | 🟡 | Elevated checks are batched into a single password prompt; a menu bar agent is on the roadmap |
| Cross-device coverage (laptop, phone, tablet) | 📋 | Linux and Windows benchmark YAMLs are on the roadmap; iOS cannot be audited from outside |
| Educational nudges and micro-tips | 🟡 | Every failing check ships a remediation step (`--verbose`); short, gamified nudges are not implemented |
| Integration with work tools | ✅ | `--json` plus a non-zero exit code on failure works in CI and MDM scripts today |

---

## Where this goes next

In priority order, the work that closes the most of the list without
compromising the "no backend, no telemetry" position:

1. **Scheduled scans with history** — drift detection, new-device alerts, and
   the monthly health report all fall out of this.
2. **One-click remediation** — every failing check already carries a
   remediation string; making it executable turns the audit into a fix.
3. **Third-party patch report** — the largest real-world gap in the update
   checks.
4. **Browser extension audit** — cheap to add, directly addresses the scam and
   tracker asks.
5. **Cross-platform benchmarks** — Linux and Windows YAMLs so one tool covers
   the household's machines.

Anything marked 🌐 stays out of the tool. If those capabilities are ever
offered, they belong in a separate, clearly-labelled opt-in service — never
silently bundled into a local auditor that currently promises to send nothing
anywhere.

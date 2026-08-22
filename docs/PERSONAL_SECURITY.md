# Personal Security Coverage

Armazi started as a CIS hardening auditor for macOS. This document maps the
things people actually ask a personal security product for — "one worry-free
shield for my identity, devices, data, home network, and family" — onto what
this repository can honestly deliver.

Every row is one of three things:

| Status | Meaning |
|---|---|
| **Shipped** | A check exists today. The check ID is listed; run it with `armazi scan --profile personal`. |
| **Planned** | Buildable inside this codebase, on the roadmap, not implemented yet. |
| **Service** | Requires a backend, a commercial data feed, or human staff. Armazi is a local, open-source binary — it can advise, but it cannot provide the service. Where a credible integration point exists, it is named. |

The personal profile deliberately does **not** repeat checks the CIS profile
already covers (FileVault, Gatekeeper, firewall, sharing services, automatic
updates, screen lock, Wi-Fi encryption). Run `armazi scan --profile all` for
both sets in one report.

---

## Identity & Account Protection

| Asked for | Status | How Armazi handles it |
|---|---|---|
| Password vault with autofill | **Shipped** | `1.5` detects an installed password manager; `P1.4` verifies iCloud Keychain syncing is on, which is what turns on Apple's leaked-password alerts. |
| MFA app, phishing-resistant options | **Shipped** | `P1.1` looks for an authenticator app; `P1.2` reports whether a FIDO2 hardware key is present. |
| Dashboard of leaked/compromised accounts | **Planned** | An `armazi breach` command can query the Have I Been Pwned range API for passwords (k-anonymity, no password leaves the machine). Breach-by-email lookups need a user-supplied HIBP API key. |
| Dark web monitoring | **Service** | Continuous monitoring needs a crawler and a subscription feed. Armazi can surface results from a provider the user already pays for; it cannot be the provider. |
| SIM-swap protection alerts | **Service** | Carrier-side. The actionable local advice — stop using SMS as a second factor — is what `P1.1` nudges toward. |
| Fraud/credit monitoring | **Service** | Bureau data, jurisdiction-specific. Out of scope. |
| — | **Shipped** | `P1.3` Apple Account signed in, `P1.5` guest account disabled, `P1.6` password hints disabled. |

## Device & Data Security

| Asked for | Status | How Armazi handles it |
|---|---|---|
| Endpoint protection (EPP/EDR) | **Shipped** | `P2.8` reports what is actually defending the Mac — XProtect and Gatekeeper, a third-party agent, or both. `P2.4` fails when malware definitions have gone stale, which is the failure mode that actually matters. |
| Ransomware rollback | **Shipped** | `P2.10` verifies Time Machine local snapshots exist, which is what a rollback depends on. |
| Encrypted backups, cloud and local | **Shipped** | `4.5` (CIS) checks the destination is encrypted; `P2.2` checks a backup has actually *run* in the last 7 days; `P2.3` checks versioned cloud storage is in use. |
| Secure cloud storage with versioning | **Shipped** | `P2.3`. |
| Remote wipe & locate | **Shipped** | `P2.1` verifies Find My Mac is enabled. |
| Patch & update manager (OS *and* apps) | **Shipped** | `P2.5` automatic security responses, `P2.6` pending macOS updates, `P2.7` outdated Homebrew packages. |
| Secure disposal (shredding, wiping) | **Partial** | `P2.9` flags mounted unencrypted external volumes — full-disk encryption is what makes disposal safe. A guided `armazi wipe` helper is **Planned**. |

## Online Safety

| Asked for | Status | How Armazi handles it |
|---|---|---|
| Phishing & scam protection in the browser | **Shipped** | `P3.1` Safari fraudulent-site warning, `P3.3` Chrome Safe Browsing. |
| Phishing protection in SMS / WhatsApp / social | **Service** | Requires message-content inspection on a phone. Out of scope for a macOS auditor. |
| Malicious-site and tracker blocking | **Shipped** | `P3.4` detects a content blocker; `P3.5` checks whether DNS points at a filtering resolver, which covers every app rather than one browser. |
| Ad blocking & privacy shielding | **Shipped** | `P3.4`, `P3.5`. |
| VPN, zero-logs, split tunneling | **Shipped (detection)** | `P3.6` reports whether a VPN service or client is configured. Armazi does not ship a VPN. |
| Public Wi-Fi protection | **Shipped** | `P3.7` flags a bloated remembered-network list — the thing that makes evil-twin attacks work. `P3.2` stops downloads auto-opening. |
| Family / child browsing | **Planned** | Screen Time and content-filter configuration checks. Multi-user coverage depends on the fleet work below. |

## Home & Network Protection

| Asked for | Status | How Armazi handles it |
|---|---|---|
| Home Wi-Fi scan & hardening | **Shipped** | `P4.1` probes the router for legacy admin services (telnet, FTP); `4.6` (CIS) checks the current network's encryption. |
| IoT security monitoring | **Partial** | `P4.2` inventories devices visible on the local network. Classifying them (TV, camera, speaker) and tracking firmware is **Planned**. |
| Alert on new/unrecognized devices | **Planned** | Requires state between scans. Falls out of the scheduled-scan + drift-detection work — the same mechanism that would notify on configuration drift. |
| Optional "home security box" | **Service** | Hardware product. The scan engine itself is portable, so a passive appliance could run this binary on a schedule. |
| — | **Shipped** | `P4.3` flags services listening on network-facing addresses; `P4.4` flags a silently configured web proxy, a common adware and MITM trait. |

## Privacy & Personal Safety

| Asked for | Status | How Armazi handles it |
|---|---|---|
| Data broker removal | **Service** | Requires filing and tracking opt-out requests per broker. Out of scope. |
| Social media privacy audit | **Service** | Needs authenticated access to each platform's account. |
| Identity theft insurance / response | **Service** | Insurance product. |
| Personal digital footprint report | **Partial** | `P5.5` catches the footprint Armazi *can* see: a computer name that broadcasts your real name over AirDrop, Bonjour, and every network you join. |
| Secure communication tools | **Shipped** | `P5.6` checks an end-to-end encrypted messenger is available. |
| — | **Shipped** | `P5.1` personalized ads off, `P5.2` analytics sharing off, `P5.3` Siri audio sharing off, `P5.4` Location Services state. |

## Monitoring & Support

| Asked for | Status | How Armazi handles it |
|---|---|---|
| Personal risk score | **Shipped** | Every scan produces a score and a per-category breakdown (`armazi status`). A weighted score — a failed FileVault check should not cost the same as a missing ad blocker — is **Planned**. |
| Monthly security health report | **Planned** | Scheduled scans plus PDF/HTML export, both already on the roadmap. |
| 24/7 hotline / concierge | **Service** | People, not software. |
| Hands-on breach assistance | **Service** | Same. What Armazi can add is a **Planned** offline playbook: what to do first when an account is taken over. |
| Family add-on accounts | **Planned** | Multi-machine reporting is the "team dashboard" roadmap item; family coverage is the same feature with a different label. |

## Convenience & Trust

| Asked for | Status | How Armazi handles it |
|---|---|---|
| Cross-device coverage | **Partial** | macOS today. Platform detection, benchmark auto-selection, and the XCCDF importer are already in place for Linux and Windows benchmarks. |
| Invisible background protection | **Planned** | Menu bar agent and scheduled scans. |
| Trusted / certified, not spyware | **Shipped** | Open source under MIT, no telemetry, no network calls except explicit update checks, SHA-256 verified downloads. Every check is a shell command you can read in the YAML and run yourself. |
| Clear pricing, easy cancellation | **N/A** | Free and open source. |
| Educational nudges | **Partial** | Every failing check carries a plain-language description and a remediation step. Micro-tips and gamification are **Planned**. |
| Integration with work tools | **Shipped** | `armazi scan --json` and a non-zero exit code on failure make it usable from CI, MDM, and scripts. |

---

## What this profile is not

Armazi is a local auditor. It reads configuration and reports risk. It does not
run in the background, does not intercept traffic, does not upload anything, and
cannot answer the phone at 2am. Roughly a third of what customers expect from a
"one-stop shield" is a *service business* wrapped around software like this —
that boundary is drawn explicitly above rather than papered over.

## Conventions for personal checks

Consumer-facing checks fail differently from hardening checks: many of the
underlying settings live in sandboxed preference domains that a terminal cannot
read without Full Disk Access, or depend on tooling that may not be installed.

* A check that cannot determine the answer prints `UNKNOWN: ...` and is marked
  `scored: false`, so it appears as a **warning to review** rather than a false
  failure. Only checks with an unambiguous system-level answer are scored.
* Checks run through `/bin/sh` — keep commands POSIX.
* Elevated checks are concatenated into one batch script for a single password
  prompt, so they must never call `exit`.

## Validation status

The audit commands in `personal-macos-benchmark.yaml` are POSIX-validated and
syntax-checked, but they have not yet been executed against a running macOS
system — this change was authored in a Linux container without a Swift
toolchain. Before tagging a release, run `armazi scan --profile personal
--verbose` on macOS 14 and 15 and confirm each check reports the expected state
on a machine whose configuration you know.

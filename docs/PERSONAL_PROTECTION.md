# Personal Protection Profile

Armazi ships two bundled benchmarks. The **CIS** profile hardens macOS against
the CIS Benchmark. The **Personal Protection** profile answers a different
question: *am I, as a person, actually protected?* — across identity, devices,
data, online safety, the home network, privacy, and what happens when something
goes wrong.

```bash
armazi scan   --profile personal            # run the check-up
armazi scan   --profile personal --level 2  # include the advanced checks
armazi status --profile personal            # one-line score
armazi list   --profile personal            # what it checks, without running it
armazi scan   --profile personal --json     # machine-readable, for your own records
```

51 checks, 6 categories, **no administrator password prompt** — nothing in this
profile is marked `elevated`, so it runs quietly.

---

## The three kinds of check

| Kind | What it does | Example |
|---|---|---|
| **Verified** | Reads the real setting from the machine | `DV.1` FileVault is on |
| **Detected** | Looks for evidence a protection exists (an installed app, a configured service) | `ID.1` a password manager is in use |
| **Attested** | Cannot be seen from the machine, so you confirm it once | `ID.10` SIM-swap protection is set with your carrier |

Attested checks are never silently passed. Until you confirm one it reports
`ARMAZI_REVIEW` and shows up as a warning — visible, but it does not fail a
scan. To confirm one:

```bash
mkdir -p ~/.config/armazi
echo ID.10 >> ~/.config/armazi/attested.txt
```

Two checks expect a **date**, because the underlying task expires — data
brokers relist you, and a security review from three years ago is not a
security review:

```bash
echo "PV.5 $(date +%Y-%m-%d)" >> ~/.config/armazi/attested.txt   # data broker removal, yearly
echo "RS.3 $(date +%Y-%m-%d)" >> ~/.config/armazi/attested.txt   # posture review, monthly
```

Delete a line to withdraw an attestation. The file is plain text, one check ID
per line, with an optional `YYYY-MM-DD` after it.

Every check in this profile reports `ARMAZI_PASS`, `ARMAZI_FAIL`, or
`ARMAZI_REVIEW`. The token is deliberately unmistakable: a check that matched
on `PASS` would also match the word "**pass**word", and one that matched on
`OK` would match "br**ok**en".

---

## Coverage

### Identity & Account Protection

| Capability | Armazi | Check |
|---|---|---|
| Password vault, cross-device, autofill | Detects a password manager or iCloud Keychain | `ID.1` |
| MFA app | Detects an authenticator on this Mac | `ID.2` |
| Phishing-resistant MFA | Security key / passkey registration | `ID.4` (attested) |
| Account takeover protection | Apple Account two-factor | `ID.3` (attested) |
| Leaked-account dashboard, dark web monitoring | Enrolment in breach monitoring | `ID.8` (attested) |
| SIM-swap protection | Carrier port-out PIN | `ID.10` (attested) |
| Fraud / credit monitoring | Bank alerts and credit monitoring | `ID.9` (attested) |
| — | Guest login disabled, screen lock delay, login window privacy | `ID.5` `ID.6` `ID.7` |

### Device & Data Security

| Capability | Armazi | Check |
|---|---|---|
| Endpoint protection (EPP/EDR) | XProtect definition freshness; detects third-party agents | `DV.9` `DV.11` |
| Ransomware rollback / quarantine | APFS local snapshots, plus a working backup chain | `DV.5` `DV.2`–`DV.4` |
| Encrypted backups, cloud **and** local | Destination configured, encrypted, and recent | `DV.2` `DV.3` `DV.4` |
| Cloud storage with versioning | iCloud Drive or another provider in use | `DV.7` |
| Remote wipe & locate | Find My Mac | `DV.6` |
| Patch & update manager (OS **and** apps) | Automatic security responses; Homebrew / App Store updates | `DV.8` `DV.10` |
| Secure disposal | Retired devices wiped; FileVault makes erase effective | `DV.12` (attested) `DV.1` |

### Online Safety

| Capability | Armazi | Check |
|---|---|---|
| Phishing & scam protection (mail, SMS, chat) | Browser fraud warnings; sender filtering | `ON.2` `ON.9` |
| Malicious site blocking | Gatekeeper; fraudulent-site warnings; filtering DNS | `ON.1` `ON.2` `ON.6` |
| Tracker & ad blocking | Cross-site tracking; content blocker installed | `ON.4` `ON.5` |
| VPN | A VPN configuration or client is available | `ON.7` |
| Public Wi-Fi protection | VPN, Private Relay, stealth mode, Wi-Fi encryption | `ON.7` `ON.8` `NW.2` `NW.3` |
| Safe family browsing | Screen Time content restrictions | `ON.10` |
| — | Downloads do not open themselves | `ON.3` |

### Home & Network Protection

| Capability | Armazi | Check |
|---|---|---|
| Wi-Fi scan & hardening | Encryption in use; router admin, firmware, WPS | `NW.3` `NW.8` |
| IoT security monitoring | Smart devices on a separate network | `NW.7` (attested) |
| **Alert on new/unrecognised devices** | Baselines the hardware addresses on your network and flags new ones on every scan | `NW.4` |
| Passive home scanning appliance | `armazi scan --profile personal --watch` on an always-on Mac | — |
| — | Firewall, stealth mode, exposed remote-access ports, AirDrop | `NW.1` `NW.2` `NW.5` `NW.6` |

`NW.4` is the one feature here that keeps state: the first scan writes
`~/.config/armazi/known-devices.txt`, and later scans report what is new. It
reads the ARP table — devices this Mac has recently talked to — it does not
scan or probe the network.

### Privacy & Personal Safety

| Capability | Armazi | Check |
|---|---|---|
| Data broker removal | Yearly removal round recorded | `PV.5` (attested, dated) |
| Social media privacy audit | Yearly review recorded | `PV.6` (attested, dated) |
| Identity theft response | Cover and contacts identified in advance | `RS.2` (attested) |
| Digital footprint report | Partly — `PV.5` and `PV.6` track the work, Armazi does not search for you | `PV.5` `PV.6` |
| Secure communication tools | Detects an end-to-end encrypted messenger | `PV.4` |
| — | Personalised ads, analytics, Siri audio sharing | `PV.1` `PV.2` `PV.3` |

### Monitoring & Support

| Capability | Armazi | Check |
|---|---|---|
| Personal risk score | The scan score — passed checks over total, per category and per framework | every scan |
| Monthly security health report | `armazi scan --profile personal --json`, plus a monthly review reminder | `RS.3` |
| Family coverage | The household runs the same check-up | `RS.4` (attested) |
| Account recovery preparation | Recovery keys, backup codes, recovery contacts stored | `RS.1` (attested) |
| Work / personal separation | Accounts, browsers, and storage kept apart | `RS.5` (attested) |
| 24/7 hotline, hands-on breach assistance | **Not covered** — this is a staffed service, not something software can provide | — |

### Convenience & Trust

| Expectation | Where Armazi stands |
|---|---|
| Cross-device coverage | macOS today. The engine is platform-agnostic and the benchmark format is portable; Linux and Windows benchmarks are on the roadmap |
| Invisible background protection | No admin prompt in this profile, no daemon, no pop-ups. `--watch` re-runs on an interval |
| Trusted, not spyware | Open source under MIT, no telemetry, no account; updates are SHA-256 verified over HTTPS |
| Clear pricing | Free |
| Portability, no lock-in | Checks are YAML you can read and edit; results export as JSON; uninstalling is deleting one binary |
| Educational nudges | Every check carries a plain-language description and a concrete remediation step, shown with `--verbose` |
| Integration with work tools | JSON output and a non-zero exit code on failure drop into any pipeline; `RS.5` covers the personal/work blur |

---

## What this profile deliberately does not do

A local auditor can tell you whether a protection is in place. It cannot *be*
the protection. The following stay out of scope, and the checks above track
them as attestations instead of pretending to deliver them:

- **Dark web and breach monitoring** — requires a service continuously watching
  breach corpora on your behalf. Armazi records that you have one (`ID.8`).
- **Data broker removal** — requires submitting and following up on legal
  requests. Armazi tracks the cadence (`PV.5`).
- **Credit, fraud, and SIM-swap monitoring** — carrier and bureau relationships
  Armazi has no access to (`ID.9`, `ID.10`).
- **Identity theft insurance and a 24/7 incident hotline** — staffed services.
  Armazi makes sure you have written down who to call (`RS.2`).
- **A VPN, a password vault, or a backup service** — Armazi checks that you use
  one; it does not become one.

Sending your device inventory, breach exposure, or account list to a third
party is exactly the risk this tool exists to reduce, so it does not do that:
Armazi has no account and no telemetry, and every result stays on the machine.
The only requests it makes are the version and benchmark update checks against
GitHub, which `--skip-update` turns off.

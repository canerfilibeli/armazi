# Armazi — Consumer Protection Feature Map

> *"Customers want a one-stop, worry-free shield for identity, devices, data, home network, and family — backed by real people they can call if something goes wrong."*

This document takes that customer wishlist item by item and answers one question for each: **what does Armazi do about it?**

It exists because the wishlist and the product are not the same shape. The list describes a *consumer security suite* — a bundle of subscriptions, services, and a call centre. Armazi is an **open-source auditor**: it inspects a machine and tells you the truth about it. That difference decides where each item lands.

---

## The three answers

Every item below gets exactly one of these.

| | Meaning |
|---|---|
| **Shipped** | Armazi checks this today. The check IDs are listed. |
| **Partial** | Part of the ask is shipped; the rest is planned or out of scope, and the row says which. |
| **Planned** | Armazi can and should check this; it is on the roadmap below. |
| **Verify-only** | Armazi will never *be* this (it is a service, a subscription, or a human), but it can verify that you have it and warn you when you do not. |
| **Out of scope** | Not something a local auditor can honestly do. Named here so nobody has to re-litigate it later. |

The distinction that matters most is **Verify-only**. Armazi does not sell a VPN, run a dark-web crawler, or staff a hotline. What it can do — and what no bundled suite does honestly, because they are selling you their own product — is tell you whether the protection is actually in place on this machine, whoever provides it.

Run the consumer-facing checks with:

```bash
armazi scan --profile personal --verbose
```

---

## 1. Identity & Account Protection

| Customer ask | Status | In Armazi |
|---|---|---|
| Password vault (secure, cross-device, autofill) | **Verify-only** | `P1.1` detects iCloud Keychain or an installed manager; `P1.2` confirms AutoFill is on, which is what makes a vault phishing-resistant in practice |
| Multi-factor authentication app, phishing-resistant | **Verify-only** | `P1.3` confirms the Apple Account is using services that require 2FA, and tells you to verify passkeys/security keys directly |
| Single dashboard of leaked/compromised accounts | **Out of scope** | Requires a breach-data service. Armazi has no account of yours and wants none |
| Automatic dark web monitoring | **Out of scope** | Same — this is a data subscription, not a device measurement |
| SIM-swap protection alerts | **Out of scope** | Carrier-side; nothing on the device can observe it |
| Fraud/credit monitoring | **Out of scope** | Regulated financial data, market by market |
| *(added)* Plain-text credential files lying around | **Shipped** | `P1.5` — the local half of "your passwords leaked": files named like credentials in Desktop, Documents, Downloads |
| *(added)* Guest account left enabled | **Shipped** | `P1.4` |

**Why so much is out of scope here.** Breach monitoring, dark-web scanning, and credit monitoring all mean "send us your email address, phone number, and government ID, and we will watch for them". That is a data-broker relationship with the user, which is the opposite of what an auditor should be. The honest local contribution is: is there a vault, is it used, is 2FA in force, and are secrets sitting in plain text.

---

## 2. Device & Data Security

| Customer ask | Status | In Armazi |
|---|---|---|
| Endpoint protection (EPP/EDR), lightweight | **Shipped** | `P2.2` verifies Gatekeeper + System Integrity Protection; `P2.3` verifies XProtect definitions are under 30 days old. macOS ships the endpoint protection — the job is confirming it is on and current |
| Ransomware protection with rollback/quarantine | **Shipped** | `P2.7` verifies APFS local snapshots exist, which is what an actual rollback needs |
| Encrypted backups, cloud and local | **Shipped** | `P2.5` (a backup from the last 7 days exists) and `P2.6` (the destination is encrypted) |
| Secure cloud storage with versioning | **Planned** | Detect iCloud Drive / Dropbox / OneDrive sync state and whether versioning is available |
| Remote wipe & locate for stolen devices | **Shipped** | `P2.8` — Find My Mac, without which remote lock and wipe do not exist |
| Patch & update manager (OS *and* apps/plugins) | **Shipped** | `P2.4` (security responses and system data files install automatically) and `P2.9` (third-party packages up to date via Homebrew) |
| Secure disposal (file shredding, wiping devices) | **Shipped** | `P2.10` — automatic Trash cleanup. On a FileVault disk (`P2.1`), emptying the Trash *is* the shredder; SSDs make overwrite-based shredding theatre |

**Note on "antivirus".** The wishlist asks for an AV product. On a current Mac the right answer is usually not a third-party scanner but confirmation that Apple's own layers — Gatekeeper, XProtect, XProtect Remediator, SIP — are enabled and current, which is exactly what `P2.2` and `P2.3` do. Armazi does not ship a scanning engine and should not.

---

## 3. Online Safety

| Customer ask | Status | In Armazi |
|---|---|---|
| Phishing & scam protection across email, SMS, WhatsApp, social | **Shipped (browser)** | `P3.1` fraudulent-site warnings, `P3.4` full URLs shown. Message-channel scanning is **out of scope** — it means reading the user's messages |
| Browser security plug-ins for malicious site blocking | **Shipped** | `P3.1`, `P3.5` (no auto-opening downloads) |
| Ad blocking & privacy shielding | **Shipped** | `P3.2` cross-site tracking prevention, `P3.6` a content blocker is installed |
| VPN — fast, zero-logs, split tunneling | **Verify-only** | `P4.5` detects a VPN configuration or client. Armazi will never operate a VPN |
| Public Wi-Fi protection | **Shipped** | `P4.2` (network encryption), `P4.3` (nothing of yours is listening), `P4.5` (a VPN is available) |
| Safe children/family browsing | **Planned** | Screen Time and Content & Privacy Restrictions are locally readable; see roadmap |

**Browser caveat.** macOS protects Safari's preferences behind Full Disk Access. Every Safari check is therefore `scored: false` and reports `UNKNOWN` rather than a false failure when it cannot read the setting. Grant your terminal Full Disk Access to get real answers from `P3.1`–`P3.5`. Firefox and Chrome profile inspection is planned.

---

## 4. Home & Network Protection

| Customer ask | Status | In Armazi |
|---|---|---|
| Home Wi-Fi scan & hardening | **Partial** | `P4.2` checks the encryption of the network you are on and tells you how to harden the router. Router-side auditing (default admin password, WPS, open ports) is **planned** |
| IoT security monitoring (TVs, cameras, speakers) | **Planned** | A passive ARP/mDNS inventory can identify device classes without touching them |
| Alert on new/unrecognized devices joining the network | **Planned** | Needs the device inventory above plus a stored baseline — a natural extension of `--watch` |
| "Home security box" appliance | **Out of scope** | Hardware. Armazi is a binary you can read the source of |
| *(added)* Firewall on | **Shipped** | `P4.1` |
| *(added)* Nothing of yours is listening on the network | **Shipped** | `P4.3` — the practical version of "am I exposed on this café Wi-Fi" |
| *(added)* AirDrop not open to everyone | **Shipped** | `P4.4` |

---

## 5. Privacy & Personal Safety

| Customer ask | Status | In Armazi |
|---|---|---|
| Data broker removal service | **Out of scope** | A service that files removal requests on your behalf, month after month |
| Social media privacy audit | **Out of scope** | Requires account access to platforms |
| Identity theft insurance / response | **Out of scope** | An insurance product |
| Personal digital footprint report | **Partial → Planned** | The local half is shipped: `P5.4` catches the computer name broadcasting your real name on every network you join. The internet-wide half is out of scope |
| Secure communication tools | **Verify-only** | `P5.5` detects an installed end-to-end encrypted messenger |
| *(added)* Analytics and crash sharing off | **Shipped** | `P5.1` |
| *(added)* Personalised ads off | **Shipped** | `P5.2` |
| *(added)* IP address tracking limited | **Shipped** | `P5.3` — iCloud Private Relay |

---

## 6. Monitoring & Support

| Customer ask | Status | In Armazi |
|---|---|---|
| Personal risk score | **Shipped** | Every scan produces a score (pass rate over the profile), per-category breakdown in `armazi status`, and a score ring in the GUI |
| Monthly security health report | **Planned** | `armazi scan --json` is the data; scheduled scans + a PDF/HTML report are on the roadmap |
| 24/7 hotline / concierge | **Out of scope** | People, not software |
| Breach assistance | **Out of scope** | Same |
| Family add-on accounts | **Planned (different shape)** | Not "accounts" — a multi-machine view. The roadmap's team/fleet dashboard covers a household as well as a company |

**On the score.** The wishlist asks for "a credit score for cybersecurity hygiene". Armazi's score is deliberately a plain pass rate over a published, readable list of checks: you can see every check that moved it and why. An opaque proprietary score would be easier to market and worth less.

---

## 7. Convenience & Trust

| Customer ask | Status | In Armazi |
|---|---|---|
| Cross-device coverage (laptop, phone, tablet) | **Partial** | macOS today; Linux and Windows benchmark support is in progress. iOS/Android cannot be audited from a companion app in any meaningful way |
| Invisible background protection, low friction | **Partial** | The CLI is non-interactive and CI-friendly; elevated checks are batched into a single password prompt. A menu-bar agent is on the roadmap |
| Trusted brand / certified — "not spyware" | **Shipped** | MIT-licensed, auditable source, no telemetry, no account, no network calls except explicit update checks. Every check is a YAML file you can read |
| Clear pricing | **Shipped** | Free |
| Easy cancellation / portability | **Shipped** | `brew uninstall armazi`. Reports are JSON you own |
| Educational nudges, micro-tips | **Partial** | Every check carries a `description` (why it matters) and a `remediation` (exactly what to click). `--verbose` prints both |
| Integration with work tools | **Partial** | `--json` output and a non-zero exit code on failure make it usable in CI and MDM workflows |

---

## Roadmap implied by this list

Ordered by (customer value × how cleanly it fits an auditor).

**Near term**
1. **Scheduled scans + drift alerts** — the delivery mechanism for "monthly health report" and "alert me when something changes". Already listed on the README roadmap; the personal profile makes it consumer-relevant.
2. **HTML/PDF report export** — a health report a non-technical family member can read.
3. **Menu-bar agent** — the "invisible background protection" ask; score in the menu bar, nudge only when it drops.
4. **Full Disk Access guidance** — detect the missing permission once and explain it, instead of five `UNKNOWN` browser checks.

**Medium term**
5. **Home network inventory** — passive ARP/mDNS device list, stored baseline, alert on new devices. Covers three IoT/home items at once.
6. **Router hardening checks** — reachable admin interface over plain HTTP, default credentials *of the gateway you are on*, UPnP exposure. Read-only probes of your own gateway, never scanning.
7. **Family/household view** — several machines reporting into one place. Same machinery as the fleet dashboard.
8. **Screen Time / parental controls checks** — "safe children browsing", locally readable.
9. **Firefox and Chrome profile checks** — the Safari checks generalised.

**Longer term**
10. **Cross-platform parity** — the Linux and Windows benchmarks already on the roadmap, plus a personal profile for each.
11. **Remediation actions** — one-click fixes for the checks whose remediation is a single defaults write, with an explicit confirmation for each.

---

## What Armazi deliberately will not become

Stated plainly so that it does not need re-deciding every quarter:

- **A VPN, a backup service, a password manager, or a cloud drive.** It verifies that you have these. Bundling them would mean an auditor with a commercial interest in its own verdicts.
- **A breach/dark-web/credit monitoring service.** These require collecting the user's identity data. Armazi's entire trust proposition is that it collects nothing and phones nowhere.
- **A message scanner.** "Phishing protection across email, SMS, WhatsApp" means reading private messages. Browser-level anti-phishing gets most of the protection with none of the intrusion.
- **An insurance product or a support hotline.** Real answers to those exist; they are not software.

The honest pitch is narrower than the wishlist and more defensible: **Armazi tells you, in one screen and without collecting anything, which of these protections are actually in place on your machine — and exactly what to click for each one that is not.**

---

## Appendix — the personal profile at a glance

```bash
armazi list --profile personal          # every check, by category
armazi scan --profile personal          # run them
armazi status --profile personal        # one-line score + per-category breakdown
armazi scan --profile personal --json   # machine-readable
```

| Category | Checks | Covers |
|---|---|---|
| Identity & Accounts | `P1.1`–`P1.5` | Vault, AutoFill, 2FA, guest account, plain-text secrets |
| Device & Data | `P2.1`–`P2.10` | FileVault, malware protection, definitions, patching, backups, snapshots, Find My, app updates, disposal |
| Online Safety | `P3.1`–`P3.6` | Phishing warnings, tracker blocking, pop-ups, full URLs, downloads, content blocker |
| Home & Network | `P4.1`–`P4.5` | Firewall, Wi-Fi encryption, exposed services, AirDrop, VPN |
| Privacy | `P5.1`–`P5.5` | Analytics, ads, IP tracking, device name, encrypted messaging |

Checks that depend on data macOS protects (Safari settings in particular) are advisory — they report `UNKNOWN` instead of failing when the setting cannot be read, so a missing permission never masquerades as a security problem. Editing or extending them needs no Swift: they are plain YAML in `Sources/ArmaziCore/Benchmarks/personal-protection-macos.yaml`.

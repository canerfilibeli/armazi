import Foundation

/// Bundled CIS macOS Benchmark embedded as a string literal.
/// This avoids the need for Bundle.module resource loading,
/// making the binary fully self-contained.
enum EmbeddedBenchmarks {
    static let cisMacOS: String = #"""
name: "CIS macOS Benchmark"
version: "1.0.0"
platform: "macOS"
description: "Security configuration benchmark for macOS based on CIS Controls, ISO 27001, NIST CSF, Cyber Essentials, and SOC frameworks."

checks:
  # ──────────────────────────────────────────────
  # Access Security
  # ──────────────────────────────────────────────

  - id: "1.1"
    title: "Automatic Login is off"
    description: "Prevent unauthorized access by disabling automatic login."
    category: "access_security"
    level: 1
    scored: true
    audit:
      command: "defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>&1"
      match:
        type: "contains"
        value: "does not exist"
    remediation: "sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  - id: "1.2"
    title: "No unused user accounts are present"
    description: "Delete unnecessary user accounts to reduce the attack surface."
    category: "access_security"
    level: 1
    scored: true
    audit:
      command: |
        unused=0
        for user in $(dscl . -list /Users UniqueID | awk '$2 >= 500 {print $1}'); do
          [ "$user" = "nobody" ] && continue
          lastlog=$(last -1 "$user" 2>/dev/null | head -1)
          if echo "$lastlog" | grep -q "wtmp begins"; then
            unused=$((unused + 1))
          fi
        done
        [ "$unused" -eq 0 ] && echo "PASS: no unused accounts" || echo "FAIL: $unused unused account(s) found"
      match:
        type: "contains"
        value: "PASS"
    remediation: "Remove unused accounts via System Settings > Users & Groups, or run: sudo dscl . -delete /Users/<username>"
    frameworks: ["cis", "iso", "essentials"]

  - id: "1.3"
    title: "Not using Administrator account"
    description: "Limit daily use of the Administrator account to reduce risk."
    category: "access_security"
    level: 1
    scored: true
    audit:
      command: |
        current_user=$(stat -f '%Su' /dev/console)
        if id -Gn "$current_user" 2>/dev/null | grep -qw admin; then
          # Check if user is the original admin (UID 501 is typically the first user)
          uid=$(id -u "$current_user")
          if [ "$uid" -eq 0 ]; then
            echo "FAIL: running as root"
          else
            echo "WARNING: user is in admin group"
          fi
        else
          echo "PASS: standard user"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "Create a standard user account for daily use and only use the admin account when necessary."
    frameworks: ["cis", "essentials"]

  - id: "1.4"
    title: "Password after inactivity"
    description: "Require password immediately after screen saver or sleep to prevent unauthorized access."
    category: "access_security"
    level: 1
    scored: true
    audit:
      command: |
        ask=$(sysadminctl -screenLock status 2>&1)
        if echo "$ask" | grep -q "screenLock is on"; then
          echo "PASS: screen lock enabled"
        elif echo "$ask" | grep -q "screenLock is off"; then
          echo "FAIL: screen lock disabled"
        else
          # Fallback to defaults
          ask_pw=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
          delay=$(defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null)
          if [ "$ask_pw" = "1" ] && [ "${delay:-999}" -le 5 ]; then
            echo "PASS: password required after screensaver"
          else
            echo "FAIL: password not required or delay too long"
          fi
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > Lock Screen > Require password after screen saver begins or display is turned off → Immediately"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  - id: "1.5"
    title: "Password manager is installed"
    description: "Use a password manager to manage passwords securely."
    category: "access_security"
    level: 1
    scored: false
    audit:
      command: |
        managers="1Password Bitwarden KeePassXC Dashlane LastPass Enpass RoboForm Keeper"
        found=""
        for app in $managers; do
          if ls /Applications/ 2>/dev/null | grep -qi "$app"; then
            found="$found $app"
          fi
          if ls "$HOME/Applications/" 2>/dev/null | grep -qi "$app"; then
            found="$found $app"
          fi
        done
        if [ -n "$found" ]; then
          echo "PASS: found password manager(s):$found"
        else
          echo "FAIL: no password manager found"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "Install a password manager such as 1Password, Bitwarden, or KeePassXC."
    frameworks: ["nist-csf", "essentials", "soc"]

  - id: "1.6"
    title: "Password to unlock Preferences"
    description: "Require an admin password for changing system-wide settings."
    category: "access_security"
    level: 1
    scored: false
    elevated: true
    audit:
      command: |
        result=$(security authorizationdb read system.preferences 2>/dev/null | grep -c "shared.*false")
        if [ "$result" -ge 1 ]; then
          echo "PASS: admin password required for preferences"
        else
          echo "FAIL: preferences may not require admin password"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > Privacy & Security > Advanced > Require an administrator password to access system-wide settings"
    frameworks: []

  - id: "1.7"
    title: "Screen Saver shows after 20 minutes"
    description: "Activate screen saver after a period of inactivity to prevent unauthorized access."
    category: "access_security"
    level: 1
    scored: true
    audit:
      command: |
        idle_time=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null)
        if [ -z "$idle_time" ] || [ "$idle_time" -eq 0 ]; then
          echo "FAIL: screen saver idle time not set"
        elif [ "$idle_time" -le 1200 ]; then
          echo "PASS: screen saver activates after ${idle_time}s"
        else
          echo "FAIL: screen saver idle time is ${idle_time}s (>1200s)"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > Screen Saver > Show screen saver after → 20 minutes or less"
    frameworks: ["cis", "iso", "nist-csf", "soc"]

  - id: "1.8"
    title: "SSH keys require a password"
    description: "Protect SSH private keys with a passphrase."
    category: "access_security"
    level: 1
    scored: false
    audit:
      command: |
        found_keys=0
        unprotected=0
        for key in "$HOME"/.ssh/id_*; do
          [ -f "$key" ] || continue
          echo "$key" | grep -q '\.pub$' && continue
          found_keys=$((found_keys + 1))
          if ssh-keygen -y -P "" -f "$key" >/dev/null 2>&1; then
            unprotected=$((unprotected + 1))
          fi
        done
        if [ "$found_keys" -eq 0 ]; then
          echo "PASS: no SSH keys found"
        elif [ "$unprotected" -eq 0 ]; then
          echo "PASS: all $found_keys SSH key(s) are passphrase-protected"
        else
          echo "FAIL: $unprotected of $found_keys SSH key(s) have no passphrase"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "Add a passphrase to unprotected keys: ssh-keygen -p -f ~/.ssh/id_<type>"
    frameworks: []

  - id: "1.9"
    title: "SSH keys use strong encryption"
    description: "Use strong key algorithms (Ed25519 or RSA ≥3072-bit) to prevent brute-force attacks."
    category: "access_security"
    level: 1
    scored: false
    audit:
      command: |
        found_keys=0
        weak=0
        for key in "$HOME"/.ssh/id_*.pub; do
          [ -f "$key" ] || continue
          found_keys=$((found_keys + 1))
          info=$(ssh-keygen -l -f "$key" 2>/dev/null)
          bits=$(echo "$info" | awk '{print $1}')
          type=$(echo "$info" | awk '{print $NF}' | tr -d '()')
          case "$type" in
            ED25519) ;;  # Always strong
            RSA)
              if [ "$bits" -lt 3072 ]; then
                weak=$((weak + 1))
              fi
              ;;
            DSA|ECDSA)
              weak=$((weak + 1))
              ;;
          esac
        done
        if [ "$found_keys" -eq 0 ]; then
          echo "PASS: no SSH keys found"
        elif [ "$weak" -eq 0 ]; then
          echo "PASS: all $found_keys key(s) use strong encryption"
        else
          echo "FAIL: $weak of $found_keys key(s) use weak encryption"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "Generate a new key with strong encryption: ssh-keygen -t ed25519"
    frameworks: []

  # ──────────────────────────────────────────────
  # Firewall & Sharing
  # ──────────────────────────────────────────────

  - id: "2.1"
    title: "AirDrop is secured"
    description: "Disable or restrict AirDrop to contacts only when not in use."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: |
        mode=$(defaults read com.apple.sharingd DiscoverableMode 2>/dev/null)
        case "$mode" in
          "Off"|"Contacts Only")
            echo "PASS: AirDrop is set to $mode"
            ;;
          "Everyone")
            echo "FAIL: AirDrop is set to Everyone"
            ;;
          *)
            echo "PASS: AirDrop DiscoverableMode not set (defaults to Contacts Only)"
            ;;
        esac
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > AirDrop & Handoff > AirDrop → Contacts Only or No One"
    frameworks: ["cis", "essentials"]

  - id: "2.2"
    title: "AirPlay Receiver is off"
    description: "Disable the AirPlay receiver to prevent unauthorized streaming."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: |
        enabled=$(defaults -currentHost read com.apple.controlcenter AirplayRecieverEnabled 2>/dev/null)
        if [ "$enabled" = "0" ]; then
          echo "PASS: AirPlay Receiver is off"
        elif [ "$enabled" = "1" ]; then
          echo "FAIL: AirPlay Receiver is on"
        else
          echo "PASS: AirPlay Receiver not configured (defaults to off)"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > AirDrop & Handoff > AirPlay Receiver → Off"
    frameworks: ["cis", "essentials"]

  - id: "2.3"
    title: "File Sharing is off"
    description: "Disable file sharing (SMB) when not needed."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: |
        if launchctl list 2>/dev/null | grep -q "com.apple.smbd"; then
          echo "FAIL: SMB File Sharing is enabled"
        else
          echo "PASS: SMB File Sharing is off"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Sharing > File Sharing → Off"
    frameworks: ["cis", "essentials"]

  - id: "2.4"
    title: "Firewall is on and configured"
    description: "Enable the macOS firewall to block unauthorized incoming connections."
    category: "firewall_sharing"
    level: 1
    scored: true
    elevated: true
    audit:
      command: "/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1"
      match:
        type: "contains"
        value: "enabled"
    remediation: "System Settings > Network > Firewall → Turn On. Or run: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
    frameworks: ["cis", "iso", "essentials", "soc"]

  - id: "2.5"
    title: "Internet Sharing is off"
    description: "Disable Internet Sharing to prevent your Mac from acting as a router."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: |
        sharing=$(defaults read /Library/Preferences/SystemConfiguration/com.apple.nat NAT 2>/dev/null | grep -c "Enabled = 1")
        if [ "$sharing" -ge 1 ]; then
          echo "FAIL: Internet Sharing is enabled"
        else
          echo "PASS: Internet Sharing is off"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Sharing > Internet Sharing → Off"
    frameworks: ["cis", "essentials"]

  - id: "2.6"
    title: "Media Sharing is off"
    description: "Disable media sharing to prevent exposing media libraries on the network."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: |
        home_sharing=$(defaults read com.apple.amp.mediasharingd home-sharing-enabled 2>/dev/null)
        media_sharing=$(defaults read com.apple.amp.mediasharingd public-sharing-enabled 2>/dev/null)
        if [ "$home_sharing" = "1" ] || [ "$media_sharing" = "1" ]; then
          echo "FAIL: Media Sharing is enabled"
        else
          echo "PASS: Media Sharing is off"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Sharing > Media Sharing → Off"
    frameworks: ["cis", "essentials"]

  - id: "2.7"
    title: "Printer Sharing is off"
    description: "Disable printer sharing to reduce the attack surface."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: |
        sharing=$(cupsctl 2>/dev/null | grep "_share_printers" | grep -c "1")
        if [ "$sharing" -ge 1 ]; then
          echo "FAIL: Printer Sharing is enabled"
        else
          echo "PASS: Printer Sharing is off"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Sharing > Printer Sharing → Off. Or run: cupsctl --no-share-printers"
    frameworks: ["cis", "essentials"]

  - id: "2.8"
    title: "Remote Login is off"
    description: "Disable SSH remote login when not required."
    category: "firewall_sharing"
    level: 1
    scored: true
    elevated: true
    audit:
      command: |
        if systemsetup -getremotelogin 2>/dev/null | grep -qi "off"; then
          echo "PASS: Remote Login (SSH) is off"
        elif launchctl list 2>/dev/null | grep -q "com.openssh.sshd"; then
          echo "FAIL: Remote Login (SSH) is on"
        else
          echo "PASS: Remote Login (SSH) is off"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Sharing > Remote Login → Off. Or run: sudo systemsetup -setremotelogin off"
    frameworks: ["cis", "essentials"]

  - id: "2.9"
    title: "Remote Management is off"
    description: "Disable Apple Remote Desktop agent when not needed."
    category: "firewall_sharing"
    level: 1
    scored: true
    audit:
      command: |
        if launchctl list 2>/dev/null | grep -q "com.apple.ARDAgent"; then
          echo "FAIL: Remote Management (ARD) is enabled"
        else
          echo "PASS: Remote Management is off"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Sharing > Remote Management → Off. Or run: sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop"
    frameworks: ["cis", "essentials"]

  # ──────────────────────────────────────────────
  # macOS Updates
  # ──────────────────────────────────────────────

  - id: "3.1"
    title: "App Store updates are automatic"
    description: "Enable automatic App Store updates to keep software patched."
    category: "updates"
    level: 1
    scored: true
    audit:
      command: |
        auto=$(defaults read /Library/Preferences/com.apple.commerce AutoUpdate 2>/dev/null)
        if [ "$auto" = "1" ]; then
          echo "PASS: App Store auto-update is enabled"
        else
          echo "FAIL: App Store auto-update is disabled or not set"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Software Update > Automatic Updates > Install App Updates from the App Store → On"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  - id: "3.2"
    title: "Application updates are automatic"
    description: "Automatically install application updates to stay protected."
    category: "updates"
    level: 1
    scored: true
    audit:
      command: |
        auto_app=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallAppUpdates 2>/dev/null)
        if [ "$auto_app" = "1" ]; then
          echo "PASS: automatic app updates enabled"
        else
          echo "FAIL: automatic app updates disabled or not set"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Software Update > Automatic Updates > Install application updates → On"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  - id: "3.3"
    title: "macOS updates are automatic"
    description: "Enable automatic macOS updates to receive security patches promptly."
    category: "updates"
    level: 1
    scored: true
    audit:
      command: |
        check_enabled=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null)
        auto_download=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null)
        if [ "$check_enabled" = "1" ] && [ "$auto_download" = "1" ]; then
          echo "PASS: macOS automatic updates enabled"
        else
          echo "FAIL: macOS automatic updates not fully enabled (check=$check_enabled, download=$auto_download)"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Software Update > Automatic Updates → Turn on Check for updates and Download new updates"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  # ──────────────────────────────────────────────
  # System Integrity
  # ──────────────────────────────────────────────

  - id: "4.1"
    title: "Boot is secure"
    description: "Ensure the Mac uses Full Security boot policy."
    category: "system_integrity"
    level: 1
    scored: true
    elevated: true
    audit:
      command: |
        arch=$(uname -m)
        if [ "$arch" = "arm64" ]; then
          # Apple Silicon — check via bputil
          policy=$(bputil --display-all-policies 2>&1)
          if echo "$policy" | grep -qi "full security"; then
            echo "PASS: Full Security boot policy is set"
          elif echo "$policy" | grep -qi "security"; then
            echo "FAIL: Reduced or Permissive security boot policy detected"
          else
            # bputil may require elevated privileges
            echo "WARNING: could not determine boot policy (may need sudo)"
          fi
        else
          # Intel — check SIP via csrutil
          sip=$(csrutil status 2>&1)
          if echo "$sip" | grep -qi "enabled"; then
            echo "PASS: SIP is enabled (Intel)"
          else
            echo "FAIL: SIP is disabled (Intel)"
          fi
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "Restart into Recovery Mode > Startup Security Utility > Set to Full Security"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  - id: "4.2"
    title: "FileVault is on"
    description: "Encrypt the startup disk with FileVault to protect data at rest."
    category: "system_integrity"
    level: 1
    scored: true
    audit:
      command: "fdesetup status 2>&1"
      match:
        type: "contains"
        value: "FileVault is On"
    remediation: "System Settings > Privacy & Security > FileVault → Turn On"
    frameworks: ["cis", "iso", "nist-csf", "soc"]

  - id: "4.3"
    title: "Gatekeeper is on"
    description: "Gatekeeper prevents running applications that are not notarized by Apple."
    category: "system_integrity"
    level: 1
    scored: true
    audit:
      command: "spctl --status 2>&1"
      match:
        type: "contains"
        value: "assessments enabled"
    remediation: "sudo spctl --master-enable"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  - id: "4.4"
    title: "Terminal apps use secure keyboard entry"
    description: "Secure keyboard entry prevents other apps from intercepting keystrokes in Terminal."
    category: "system_integrity"
    level: 1
    scored: false
    audit:
      command: |
        secure=$(defaults read com.apple.Terminal SecureKeyboardEntry 2>/dev/null)
        if [ "$secure" = "1" ]; then
          echo "PASS: Terminal secure keyboard entry is enabled"
        else
          echo "FAIL: Terminal secure keyboard entry is disabled"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "Terminal > Settings > Profiles > Keyboard > Secure Keyboard Entry → On"
    frameworks: []

  - id: "4.5"
    title: "Time Machine is on and encrypted"
    description: "Use encrypted Time Machine backups to protect your data."
    category: "system_integrity"
    level: 1
    scored: true
    audit:
      command: |
        dest=$(tmutil destinationinfo 2>&1)
        if echo "$dest" | grep -q "No destinations"; then
          echo "FAIL: Time Machine has no backup destination configured"
        else
          name=$(echo "$dest" | grep "Name" | head -1 | awk -F: '{print $2}' | xargs)
          if echo "$dest" | grep -qi "encrypted.*yes\|Encryption Status.*Encrypted"; then
            echo "PASS: Time Machine is configured with encrypted backup ($name)"
          else
            echo "FAIL: Time Machine backup is not encrypted ($name)"
          fi
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "System Settings > General > Time Machine > Add Backup Disk and enable 'Encrypt Backups'"
    frameworks: ["cis", "iso", "nist-csf", "essentials", "soc"]

  - id: "4.6"
    title: "Wi-Fi connection is secure"
    description: "Ensure the current Wi-Fi connection uses WPA2 or WPA3 encryption."
    category: "system_integrity"
    level: 1
    scored: false
    audit:
      command: |
        # Try the modern networksetup approach first
        wifi_if=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|AirPort/{getline; print $NF}')
        if [ -z "$wifi_if" ]; then
          echo "PASS: no Wi-Fi interface found (wired connection)"
          exit 0
        fi
        info=$(system_profiler SPAirPortDataType 2>/dev/null)
        security=$(echo "$info" | grep -A1 "Current Network" | grep -i "security" | head -1)
        if [ -z "$security" ]; then
          # Alternative: use airport utility
          security=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | grep -i "link auth")
        fi
        if echo "$security" | grep -qiE "WPA3|WPA2"; then
          echo "PASS: Wi-Fi using secure encryption ($security)"
        elif echo "$security" | grep -qiE "WEP|None|Open"; then
          echo "FAIL: Wi-Fi using weak or no encryption ($security)"
        else
          echo "WARNING: could not determine Wi-Fi security ($security)"
        fi
      match:
        type: "contains"
        value: "PASS"
    remediation: "Connect to a Wi-Fi network that uses WPA2 or WPA3 encryption."
    frameworks: ["iso"]
"""#
}

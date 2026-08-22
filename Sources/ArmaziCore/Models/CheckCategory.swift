import SwiftUI

public enum CheckCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    // System hardening (CIS macOS Benchmark)
    case accessSecurity = "access_security"
    case firewallSharing = "firewall_sharing"
    case updates = "updates"
    case systemIntegrity = "system_integrity"

    // Personal security (Armazi Personal Security Benchmark)
    case identityProtection = "identity_protection"
    case dataProtection = "data_protection"
    case onlineSafety = "online_safety"
    case networkProtection = "network_protection"
    case privacy = "privacy"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .accessSecurity: "Access Security"
        case .firewallSharing: "Firewall & Sharing"
        case .updates: "macOS Updates"
        case .systemIntegrity: "System Integrity"
        case .identityProtection: "Identity & Accounts"
        case .dataProtection: "Device & Data"
        case .onlineSafety: "Online Safety"
        case .networkProtection: "Home Network"
        case .privacy: "Privacy"
        }
    }

    public var icon: String {
        switch self {
        case .accessSecurity: "lock.shield.fill"
        case .firewallSharing: "network.badge.shield.half.filled"
        case .updates: "arrow.triangle.2.circlepath"
        case .systemIntegrity: "cpu.fill"
        case .identityProtection: "person.badge.key.fill"
        case .dataProtection: "externaldrive.badge.checkmark"
        case .onlineSafety: "safari.fill"
        case .networkProtection: "wifi.router.fill"
        case .privacy: "hand.raised.fill"
        }
    }

    public var color: Color {
        switch self {
        case .accessSecurity: .blue
        case .firewallSharing: .purple
        case .updates: .orange
        case .systemIntegrity: .green
        case .identityProtection: .pink
        case .dataProtection: .teal
        case .onlineSafety: .cyan
        case .networkProtection: .indigo
        case .privacy: .mint
        }
    }
}

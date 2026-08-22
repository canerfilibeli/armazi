import SwiftUI

public enum CheckCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case accessSecurity = "access_security"
    case firewallSharing = "firewall_sharing"
    case updates = "updates"
    case systemIntegrity = "system_integrity"
    case identityProtection = "identity_protection"
    case dataProtection = "data_protection"
    case privacy = "privacy"
    case networkProtection = "network_protection"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .accessSecurity: "Access Security"
        case .firewallSharing: "Firewall & Sharing"
        case .updates: "macOS Updates"
        case .systemIntegrity: "System Integrity"
        case .identityProtection: "Identity & Accounts"
        case .dataProtection: "Backup & Data"
        case .privacy: "Privacy & Online Safety"
        case .networkProtection: "Network & IoT"
        }
    }

    public var icon: String {
        switch self {
        case .accessSecurity: "lock.shield.fill"
        case .firewallSharing: "network.badge.shield.half.filled"
        case .updates: "arrow.triangle.2.circlepath"
        case .systemIntegrity: "cpu.fill"
        case .identityProtection: "person.badge.key.fill"
        case .dataProtection: "externaldrive.fill.badge.timemachine"
        case .privacy: "hand.raised.fill"
        case .networkProtection: "antenna.radiowaves.left.and.right"
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
        case .privacy: .indigo
        case .networkProtection: .mint
        }
    }
}

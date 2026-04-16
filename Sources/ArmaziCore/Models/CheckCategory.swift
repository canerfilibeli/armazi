import SwiftUI

public enum CheckCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case accessSecurity = "access_security"
    case firewallSharing = "firewall_sharing"
    case updates = "updates"
    case systemIntegrity = "system_integrity"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .accessSecurity: "Access Security"
        case .firewallSharing: "Firewall & Sharing"
        case .updates: "macOS Updates"
        case .systemIntegrity: "System Integrity"
        }
    }

    public var icon: String {
        switch self {
        case .accessSecurity: "lock.shield.fill"
        case .firewallSharing: "network.badge.shield.half.filled"
        case .updates: "arrow.triangle.2.circlepath"
        case .systemIntegrity: "cpu.fill"
        }
    }

    public var color: Color {
        switch self {
        case .accessSecurity: .blue
        case .firewallSharing: .purple
        case .updates: .orange
        case .systemIntegrity: .green
        }
    }
}

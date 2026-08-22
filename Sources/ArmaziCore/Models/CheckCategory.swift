import SwiftUI

public enum CheckCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case accessSecurity = "access_security"
    case firewallSharing = "firewall_sharing"
    case updates = "updates"
    case systemIntegrity = "system_integrity"
    case identityProtection = "identity_protection"
    case deviceData = "device_data"
    case onlineSafety = "online_safety"
    case homeNetwork = "home_network"
    case privacyFootprint = "privacy_footprint"
    case responseReadiness = "response_readiness"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .accessSecurity: "Access Security"
        case .firewallSharing: "Firewall & Sharing"
        case .updates: "macOS Updates"
        case .systemIntegrity: "System Integrity"
        case .identityProtection: "Identity & Accounts"
        case .deviceData: "Device & Data"
        case .onlineSafety: "Online Safety"
        case .homeNetwork: "Home & Network"
        case .privacyFootprint: "Privacy & Footprint"
        case .responseReadiness: "Response Readiness"
        }
    }

    public var icon: String {
        switch self {
        case .accessSecurity: "lock.shield.fill"
        case .firewallSharing: "network.badge.shield.half.filled"
        case .updates: "arrow.triangle.2.circlepath"
        case .systemIntegrity: "cpu.fill"
        case .identityProtection: "person.badge.key.fill"
        case .deviceData: "externaldrive.fill.badge.checkmark"
        case .onlineSafety: "globe.badge.chevron.backward"
        case .homeNetwork: "wifi.router.fill"
        case .privacyFootprint: "eye.slash.fill"
        case .responseReadiness: "cross.case.fill"
        }
    }

    public var color: Color {
        switch self {
        case .accessSecurity: .blue
        case .firewallSharing: .purple
        case .updates: .orange
        case .systemIntegrity: .green
        case .identityProtection: .blue
        case .deviceData: .green
        case .onlineSafety: .purple
        case .homeNetwork: .teal
        case .privacyFootprint: .indigo
        case .responseReadiness: .pink
        }
    }
}

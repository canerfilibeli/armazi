import SwiftUI

public enum ComplianceFramework: String, Codable, Sendable, CaseIterable, Identifiable {
    case cis = "cis"
    case iso27001 = "iso"
    case nistCSF = "nist-csf"
    case cyberEssentials = "essentials"
    case soc = "soc"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cis: "CIS"
        case .iso27001: "ISO"
        case .nistCSF: "NIST CSF"
        case .cyberEssentials: "Essentials"
        case .soc: "SOC"
        }
    }

    public var fullName: String {
        switch self {
        case .cis: "CIS Critical Security Controls"
        case .iso27001: "ISO 27001"
        case .nistCSF: "NIST Cybersecurity Framework"
        case .cyberEssentials: "Cyber Essentials"
        case .soc: "System and Organization Controls"
        }
    }

    public var color: Color {
        switch self {
        case .cis: .blue
        case .iso27001: .purple
        case .nistCSF: .teal
        case .cyberEssentials: .orange
        case .soc: .indigo
        }
    }
}

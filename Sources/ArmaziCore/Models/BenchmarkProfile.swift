import Foundation

/// A bundled benchmark profile — which set of checks to run.
public enum BenchmarkProfile: String, CaseIterable, Codable, Identifiable, Sendable {
    /// System hardening checks from the CIS macOS Benchmark.
    case cis
    /// Consumer-focused identity, backup, browsing, home-network, and privacy checks.
    case personal
    /// Both profiles in a single report.
    case all

    public static let `default`: BenchmarkProfile = .cis

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cis: "System Hardening"
        case .personal: "Personal Security"
        case .all: "Everything"
        }
    }

    public var summary: String {
        switch self {
        case .cis: "CIS macOS Benchmark — system configuration hardening."
        case .personal: "Identity, backups, safe browsing, home network, and privacy."
        case .all: "Every bundled check, system hardening and personal security."
        }
    }
}

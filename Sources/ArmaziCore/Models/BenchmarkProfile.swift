import Foundation

/// A benchmark profile bundled with Armazi.
///
/// `cis` audits a machine against the CIS macOS Benchmark — the compliance
/// view. `personal` audits the protections people actually ask for on their
/// own devices: identity, backups, browsing, home network, and privacy.
public enum BenchmarkProfile: String, CaseIterable, Codable, Sendable, Identifiable {
    case cis
    case personal

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cis: "CIS Benchmark"
        case .personal: "Personal Protection"
        }
    }

    public var summary: String {
        switch self {
        case .cis: "Compliance-oriented system hardening (CIS, ISO 27001, NIST CSF, Cyber Essentials, SOC)"
        case .personal: "Everyday protection: identity, devices and data, online safety, home network, privacy"
        }
    }

    /// Filename used for a local override in ~/.config/armazi/benchmarks.
    public var localFilename: String {
        switch self {
        case .cis: "cis-macos-benchmark.yaml"
        case .personal: "personal-protection-macos.yaml"
        }
    }
}

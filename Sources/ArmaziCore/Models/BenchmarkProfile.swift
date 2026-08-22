import Foundation

/// A benchmark that ships inside the binary and can be selected by name.
public enum BenchmarkProfile: String, CaseIterable, Codable, Identifiable, Sendable {
    /// System hardening against the CIS macOS Benchmark.
    case cis
    /// Everyday consumer protection: identity, devices, data, online safety,
    /// home network, privacy, and incident readiness.
    case personal

    public static let `default`: BenchmarkProfile = .cis

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cis: "CIS macOS Benchmark"
        case .personal: "Personal Protection"
        }
    }

    public var summary: String {
        switch self {
        case .cis: "System hardening checks from the CIS macOS Benchmark."
        case .personal: "Identity, devices, data, online safety, home network, privacy, and incident readiness."
        }
    }

    /// Filename used for a local override in ~/.config/armazi/benchmarks/.
    public var fileName: String {
        switch self {
        case .cis: "cis-macos-benchmark.yaml"
        case .personal: "personal-protection-benchmark.yaml"
        }
    }

    /// The copy compiled into the binary.
    var embeddedYAML: String {
        switch self {
        case .cis: EmbeddedBenchmarks.cisMacOS
        case .personal: EmbeddedBenchmarks.personalProtection
        }
    }
}

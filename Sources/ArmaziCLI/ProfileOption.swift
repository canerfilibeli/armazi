import ArgumentParser
import ArmaziCore

/// Shared help text and parsing for the `--profile` option.
enum ProfileOption {
    static let help = ArgumentHelp(
        "Benchmark profile: cis (system hardening) or personal (everyday protection).",
        valueName: "name"
    )

    static func parse(_ raw: String) throws -> BenchmarkProfile {
        guard let profile = BenchmarkProfile(rawValue: raw.lowercased()) else {
            let available = BenchmarkProfile.allCases.map(\.rawValue).joined(separator: ", ")
            throw ValidationError("Unknown profile '\(raw)'. Available profiles: \(available)")
        }
        return profile
    }
}

import ArgumentParser
import Foundation
import ArmaziCore

/// Shared benchmark resolution for the CLI subcommands.
enum BenchmarkLoading {

    static let profileHelp = ArgumentHelp(
        "Bundled profile to use: \(BenchmarkProfile.allCases.map(\.rawValue).joined(separator: " or "))."
    )

    /// Resolve which benchmark to run from an explicit file path or a bundled profile name.
    static func load(path: String?, profile: String) throws -> BenchmarkDefinition {
        if let path {
            return try BenchmarkParser.parse(fileURL: URL(fileURLWithPath: path))
        }
        let resolved = try resolve(profile)
        return try BenchmarkParser.loadBundled(profile: resolved)
    }

    /// Map a --profile value to a BenchmarkProfile, or explain what is available.
    static func resolve(_ profile: String) throws -> BenchmarkProfile {
        guard let resolved = BenchmarkProfile(rawValue: profile.lowercased()) else {
            let available = BenchmarkProfile.allCases
                .map { "\($0.rawValue) — \($0.summary)" }
                .joined(separator: "\n  ")
            throw ValidationError("Unknown profile '\(profile)'. Available profiles:\n  \(available)")
        }
        return resolved
    }
}

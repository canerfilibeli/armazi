import ArgumentParser
import ArmaziCore

extension BenchmarkProfile {
    /// Help text listing every selectable profile.
    static var optionHelp: String {
        let options = allCases.map(\.rawValue).joined(separator: ", ")
        return "Which bundled checks to run: \(options)."
    }

    /// Resolve a raw `--profile` value, or fail with a helpful message.
    static func resolve(_ raw: String) throws -> BenchmarkProfile {
        guard let profile = BenchmarkProfile(rawValue: raw.lowercased()) else {
            let options = allCases.map(\.rawValue).joined(separator: ", ")
            throw ValidationError("Unknown profile '\(raw)'. Choose one of: \(options).")
        }
        return profile
    }
}

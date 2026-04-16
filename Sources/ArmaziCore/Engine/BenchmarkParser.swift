import Foundation
import Yams

/// Parses benchmark definition files from YAML.
public enum BenchmarkParser {

    /// Parse a benchmark from a YAML string.
    public static func parse(yaml: String) throws -> BenchmarkDefinition {
        let decoder = YAMLDecoder()
        return try decoder.decode(BenchmarkDefinition.self, from: yaml)
    }

    /// Parse a benchmark from a file URL.
    public static func parse(fileURL: URL) throws -> BenchmarkDefinition {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return try parse(yaml: content)
    }

    /// Load the bundled CIS macOS benchmark (embedded in binary).
    public static func loadBundled() throws -> BenchmarkDefinition {
        try parse(yaml: EmbeddedBenchmarks.cisMacOS)
    }
}

public enum BenchmarkError: LocalizedError {
    case bundledFileNotFound(String)
    case invalidFormat(String)

    public var errorDescription: String? {
        switch self {
        case .bundledFileNotFound(let name):
            "Bundled benchmark '\(name)' not found."
        case .invalidFormat(let detail):
            "Invalid benchmark format: \(detail)"
        }
    }
}

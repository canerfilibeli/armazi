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

    /// Load the bundled benchmark for macOS.
    public static func loadBundled(named filename: String = "cis-macos-benchmark") throws -> BenchmarkDefinition {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "yaml", subdirectory: "Benchmarks") else {
            throw BenchmarkError.bundledFileNotFound(filename)
        }
        return try parse(fileURL: url)
    }

    /// List all bundled benchmark files.
    public static func listBundled() -> [String] {
        guard let urls = Bundle.module.urls(forResourcesWithExtension: "yaml", subdirectory: "Benchmarks") else {
            return []
        }
        return urls.map { $0.deletingPathExtension().lastPathComponent }.sorted()
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

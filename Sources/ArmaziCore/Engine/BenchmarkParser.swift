import Foundation
import Yams

/// Parses benchmark definition files from YAML.
public enum BenchmarkParser {

    /// Local benchmark storage directory.
    public static var localDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/armazi/benchmarks")
    }

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

    /// Load the best available benchmark:
    /// 1. Local override (~/.config/armazi/benchmarks/cis-macos-benchmark.yaml)
    /// 2. Embedded default (compiled into binary)
    public static func loadBundled() throws -> BenchmarkDefinition {
        let localFile = localDir.appendingPathComponent("cis-macos-benchmark.yaml")
        if FileManager.default.fileExists(atPath: localFile.path) {
            return try parse(fileURL: localFile)
        }
        return try parse(yaml: EmbeddedBenchmarks.cisMacOS)
    }

    /// List locally available benchmark files.
    public static func listLocal() -> [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: localDir, includingPropertiesForKeys: nil
        ) else { return [] }
        return contents
            .filter { $0.pathExtension == "yaml" || $0.pathExtension == "yml" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
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

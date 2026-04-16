import Foundation

/// Top-level benchmark definition parsed from a YAML file.
public struct BenchmarkDefinition: Codable, Sendable {
    public let name: String
    public let version: String
    public let platform: String
    public let description: String
    public let checks: [CheckDefinition]

    public init(name: String, version: String, platform: String, description: String, checks: [CheckDefinition]) {
        self.name = name
        self.version = version
        self.platform = platform
        self.description = description
        self.checks = checks
    }
}

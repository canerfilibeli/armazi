import Foundation

/// A single check as defined in a benchmark YAML file.
public struct CheckDefinition: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let category: CheckCategory
    public let level: Int
    public let scored: Bool
    public let audit: AuditCommand
    public let remediation: String?
    public let frameworks: [ComplianceFramework]

    public struct AuditCommand: Codable, Sendable {
        public let command: String
        public let match: MatchRule

        public init(command: String, match: MatchRule) {
            self.command = command
            self.match = match
        }
    }
}

/// Defines how to evaluate an audit command's output.
public enum MatchRule: Codable, Sendable {
    case contains(String)
    case notContains(String)
    case equals(String)
    case regex(String)
    case exitCode(Int)

    enum CodingKeys: String, CodingKey {
        case type, value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        switch type {
        case "contains": self = .contains(value)
        case "not_contains": self = .notContains(value)
        case "equals": self = .equals(value)
        case "regex": self = .regex(value)
        case "exit_code": self = .exitCode(Int(value) ?? 0)
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown match type: \(type)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .contains(let v):
            try container.encode("contains", forKey: .type)
            try container.encode(v, forKey: .value)
        case .notContains(let v):
            try container.encode("not_contains", forKey: .type)
            try container.encode(v, forKey: .value)
        case .equals(let v):
            try container.encode("equals", forKey: .type)
            try container.encode(v, forKey: .value)
        case .regex(let v):
            try container.encode("regex", forKey: .type)
            try container.encode(v, forKey: .value)
        case .exitCode(let v):
            try container.encode("exit_code", forKey: .type)
            try container.encode(String(v), forKey: .value)
        }
    }
}

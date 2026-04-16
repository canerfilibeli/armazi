import Foundation

/// The result of running a single security check.
public struct CheckResult: Identifiable, Sendable {
    public let id: String
    public let definition: CheckDefinition
    public let status: CheckStatus
    public let message: String
    public let rawOutput: String
    public let timestamp: Date

    public init(
        definition: CheckDefinition,
        status: CheckStatus,
        message: String,
        rawOutput: String = "",
        timestamp: Date = Date()
    ) {
        self.id = definition.id
        self.definition = definition
        self.status = status
        self.message = message
        self.rawOutput = rawOutput
        self.timestamp = timestamp
    }
}

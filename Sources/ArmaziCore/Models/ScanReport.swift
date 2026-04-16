import Foundation

/// A complete scan report containing all check results.
public struct ScanReport: Sendable {
    public let benchmark: BenchmarkDefinition
    public let results: [CheckResult]
    public let startedAt: Date
    public let completedAt: Date

    public var passCount: Int { results.filter { $0.status == .pass }.count }
    public var failCount: Int { results.filter { $0.status == .fail }.count }
    public var warningCount: Int { results.filter { $0.status == .warning }.count }
    public var errorCount: Int { results.filter { $0.status == .error }.count }
    public var totalChecks: Int { results.count }

    public var scorePercentage: Double {
        guard totalChecks > 0 else { return 0 }
        return Double(passCount) / Double(totalChecks) * 100
    }

    public var duration: TimeInterval {
        completedAt.timeIntervalSince(startedAt)
    }

    public func results(for category: CheckCategory) -> [CheckResult] {
        results.filter { $0.definition.category == category }
    }

    public func results(for framework: ComplianceFramework) -> [CheckResult] {
        results.filter { $0.definition.frameworks.contains(framework) }
    }
}

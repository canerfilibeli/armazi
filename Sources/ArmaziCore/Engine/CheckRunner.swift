import Foundation

/// Runs benchmark checks against the current system.
public final class CheckRunner: ObservableObject, @unchecked Sendable {
    @Published public private(set) var results: [CheckResult] = []
    @Published public private(set) var isRunning = false
    @Published public private(set) var currentCheck: String?
    @Published public private(set) var progress: Double = 0

    public init() {}

    /// Run all checks in a benchmark and return a scan report.
    /// Elevated checks are batched into a single admin password prompt.
    @MainActor
    public func run(benchmark: BenchmarkDefinition, level: Int = 1) async -> ScanReport {
        results = []
        isRunning = true
        progress = 0

        let startedAt = Date()
        let checks = benchmark.checks.filter { $0.level <= level }
        let total = Double(checks.count)

        // Pre-fetch elevated check results in one batch (single password prompt)
        let elevatedChecks = checks.filter { $0.elevated }
        var elevatedResults: [String: ShellExecutor.Result] = [:]
        if !elevatedChecks.isEmpty {
            currentCheck = "Requesting administrator privileges..."
            elevatedResults = await ShellExecutor.runElevatedBatch(
                elevatedChecks.map { ($0.id, $0.audit.command) }
            )
        }

        for (index, check) in checks.enumerated() {
            currentCheck = check.title

            let result: CheckResult
            if check.elevated, let shellResult = elevatedResults[check.id] {
                result = evaluate(check: check, shellResult: shellResult)
            } else {
                result = await runSingleCheck(check)
            }

            results.append(result)
            progress = Double(index + 1) / total
        }

        currentCheck = nil
        isRunning = false

        return ScanReport(
            benchmark: benchmark,
            results: results,
            startedAt: startedAt,
            completedAt: Date()
        )
    }

    private func runSingleCheck(_ check: CheckDefinition) async -> CheckResult {
        let shellResult = await ShellExecutor.run(check.audit.command)
        return evaluate(check: check, shellResult: shellResult)
    }

    private func evaluate(check: CheckDefinition, shellResult: ShellExecutor.Result) -> CheckResult {
        let passed: Bool
        switch check.audit.match {
        case .contains(let expected):
            passed = shellResult.output.localizedCaseInsensitiveContains(expected)

        case .notContains(let unexpected):
            passed = !shellResult.output.localizedCaseInsensitiveContains(unexpected)

        case .equals(let expected):
            passed = shellResult.output.trimmingCharacters(in: .whitespacesAndNewlines) == expected

        case .regex(let pattern):
            passed = shellResult.output.range(of: pattern, options: .regularExpression) != nil

        case .exitCode(let expected):
            passed = shellResult.exitCode == Int32(expected)
        }

        let status: CheckStatus
        if shellResult.exitCode == -1 {
            status = .error
        } else if passed {
            status = .pass
        } else {
            status = check.scored ? .fail : .warning
        }

        let message: String
        switch status {
        case .pass: message = check.title
        case .fail: message = check.description
        case .warning: message = check.description
        case .error: message = "Could not evaluate: \(shellResult.output)"
        case .skipped: message = "Check was skipped"
        }

        return CheckResult(
            definition: check,
            status: status,
            message: message,
            rawOutput: shellResult.output
        )
    }
}

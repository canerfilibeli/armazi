import Foundation
import ArmaziCore

enum CLIReporter {

    // MARK: - ANSI Colors

    static let reset   = "\u{001B}[0m"
    static let bold    = "\u{001B}[1m"
    static let dim     = "\u{001B}[2m"
    static let red     = "\u{001B}[31m"
    static let green   = "\u{001B}[32m"
    static let yellow  = "\u{001B}[33m"
    static let blue    = "\u{001B}[34m"
    static let magenta = "\u{001B}[35m"
    static let cyan    = "\u{001B}[36m"
    static let white   = "\u{001B}[37m"

    // MARK: - Status Icons

    static func icon(for status: CheckStatus) -> String {
        switch status {
        case .pass:    return "\(green)✓\(reset)"
        case .fail:    return "\(red)✗\(reset)"
        case .warning: return "\(yellow)⚠\(reset)"
        case .error:   return "\(dim)?\(reset)"
        case .skipped: return "\(dim)-\(reset)"
        }
    }

    // MARK: - Report Formatting

    static func printHeader(_ benchmark: BenchmarkDefinition) {
        print()
        print("\(bold)\(cyan)  ╔══════════════════════════════════════════════╗\(reset)")
        print("\(bold)\(cyan)  ║            ⛊  ARMAZI  ⛊                    ║\(reset)")
        print("\(bold)\(cyan)  ║     macOS Security Auditor                  ║\(reset)")
        print("\(bold)\(cyan)  ╚══════════════════════════════════════════════╝\(reset)")
        print()
        print("  \(dim)Benchmark:\(reset) \(benchmark.name) v\(benchmark.version)")
        print("  \(dim)Platform:\(reset)  \(benchmark.platform)")
        print()
    }

    static func printProgress(check: String, index: Int, total: Int) {
        let pct = Int(Double(index) / Double(total) * 100)
        print("  \(dim)[\(pct)%]\(reset) \(check)", terminator: "\r")
        fflush(stdout)
    }

    static func clearLine() {
        print("\u{001B}[2K", terminator: "\r")
    }

    static func printReport(_ report: ScanReport, verbose: Bool = false) {
        // Category sections
        for category in CheckCategory.allCases {
            let results = report.results(for: category)
            guard !results.isEmpty else { continue }

            let pass = results.filter { $0.status == .pass }.count
            let color = pass == results.count ? green : (pass > results.count / 2 ? yellow : red)

            print("  \(bold)\(category.displayName)\(reset) \(dim)[\(color)\(pass)/\(results.count)\(reset)\(dim)]\(reset)")
            print("  \(dim)\(String(repeating: "─", count: 44))\(reset)")

            for result in results {
                let statusIcon = icon(for: result.status)
                print("  \(statusIcon) \(result.definition.title)")

                if verbose && result.status != .pass {
                    print("    \(dim)→ \(result.message)\(reset)")
                    if let remediation = result.definition.remediation {
                        print("    \(dim)⚕ \(remediation)\(reset)")
                    }
                }
            }
            print()
        }

        // Summary
        let score = Int(report.scorePercentage)
        let scoreColor = score >= 80 ? green : (score >= 50 ? yellow : red)

        print("  \(bold)═══ Summary ═══\(reset)")
        print()
        print("  Score:    \(bold)\(scoreColor)\(score)%\(reset)")
        print("  Passed:   \(green)\(report.passCount)\(reset)")
        print("  Failed:   \(red)\(report.failCount)\(reset)")
        if report.warningCount > 0 {
            print("  Warnings: \(yellow)\(report.warningCount)\(reset)")
        }
        if report.errorCount > 0 {
            print("  Errors:   \(dim)\(report.errorCount)\(reset)")
        }
        print("  Duration: \(dim)\(String(format: "%.1f", report.duration))s\(reset)")
        print()

        // Framework compliance
        print("  \(bold)Frameworks\(reset)")
        for fw in ComplianceFramework.allCases {
            let results = report.results(for: fw)
            guard !results.isEmpty else { continue }
            let pass = results.filter { $0.status == .pass }.count
            let pct = Int(Double(pass) / Double(results.count) * 100)
            let fwColor = pct >= 80 ? green : (pct >= 50 ? yellow : red)
            let bar = progressBar(percentage: pct, width: 20)
            print("  \(fw.displayName.padding(toLength: 12, withPad: " ", startingAt: 0)) \(bar) \(fwColor)\(pct)%\(reset) \(dim)(\(pass)/\(results.count))\(reset)")
        }
        print()
    }

    static func printJSON(_ report: ScanReport) {
        let results = report.results.map { result -> [String: Any] in
            [
                "id": result.definition.id,
                "title": result.definition.title,
                "category": result.definition.category.rawValue,
                "status": result.status.rawValue,
                "message": result.message,
                "scored": result.definition.scored,
                "frameworks": result.definition.frameworks.map(\.rawValue),
            ]
        }

        let json: [String: Any] = [
            "benchmark": report.benchmark.name,
            "version": report.benchmark.version,
            "score": Int(report.scorePercentage),
            "passed": report.passCount,
            "failed": report.failCount,
            "total": report.totalChecks,
            "duration": round(report.duration * 10) / 10,
            "results": results,
        ]

        if let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }

    static func printCheckList(_ benchmark: BenchmarkDefinition, level: Int) {
        for category in CheckCategory.allCases {
            let checks = benchmark.checks.filter { $0.category == category && $0.level <= level }
            guard !checks.isEmpty else { continue }

            print("  \(bold)\(category.displayName)\(reset) \(dim)(\(checks.count) checks)\(reset)")
            print("  \(dim)\(String(repeating: "─", count: 44))\(reset)")

            for check in checks {
                let scored = check.scored ? "\(green)scored\(reset)" : "\(dim)info\(reset)"
                let frameworks = check.frameworks.map(\.displayName).joined(separator: " ")
                print("  \(dim)\(check.id)\(reset)  \(check.title)")
                print("       \(scored) \(dim)L\(check.level)\(reset) \(dim)\(frameworks)\(reset)")
            }
            print()
        }
    }

    // MARK: - Helpers

    private static func progressBar(percentage: Int, width: Int) -> String {
        let filled = Int(Double(percentage) / 100.0 * Double(width))
        let empty = width - filled
        let color = percentage >= 80 ? green : (percentage >= 50 ? yellow : red)
        return "\(color)\(String(repeating: "█", count: filled))\(dim)\(String(repeating: "░", count: empty))\(reset)"
    }
}

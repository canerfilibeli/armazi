import ArgumentParser
import Foundation
import ArmaziCore

struct Scan: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run security checks against your system."
    )

    @Option(name: .shortAndLong, help: "Path to a custom benchmark YAML file.")
    var benchmark: String?

    @Option(name: .shortAndLong, help: "CIS profile level (1 or 2).")
    var level: Int = 1

    @Flag(name: .shortAndLong, help: "Show detailed output with remediation steps.")
    var verbose: Bool = false

    @Flag(name: .long, help: "Output results as JSON.")
    var json: Bool = false

    @Option(name: .shortAndLong, help: "Run only checks matching this category (access_security, firewall_sharing, updates, system_integrity).")
    var category: String?

    @Option(name: .long, help: "Run only a specific check by ID.")
    var check: String?

    @Flag(name: .shortAndLong, help: "Watch mode — re-run checks every N seconds.")
    var watch: Bool = false

    @Option(name: .long, help: "Watch interval in seconds (default: 60).")
    var interval: Int = 60

    func run() async throws {
        let benchmarkDef: BenchmarkDefinition
        if let path = benchmark {
            benchmarkDef = try BenchmarkParser.parse(fileURL: URL(fileURLWithPath: path))
        } else {
            benchmarkDef = try BenchmarkParser.loadBundled()
        }

        if watch {
            try await runWatch(benchmarkDef)
        } else {
            try await runOnce(benchmarkDef)
        }
    }

    private func runOnce(_ benchmarkDef: BenchmarkDefinition) async throws {
        if !json {
            CLIReporter.printHeader(benchmarkDef)
        }

        let runner = CheckRunner()
        let report = await runner.run(benchmark: filtered(benchmarkDef), level: level)

        if json {
            CLIReporter.printJSON(report)
        } else {
            CLIReporter.printReport(report, verbose: verbose)
        }

        // Exit with non-zero if there are failures (useful for CI)
        if report.failCount > 0 {
            throw ExitCode(1)
        }
    }

    private func runWatch(_ benchmarkDef: BenchmarkDefinition) async throws {
        var previousReport: ScanReport?

        while true {
            // Clear screen
            print("\u{001B}[2J\u{001B}[H", terminator: "")

            CLIReporter.printHeader(benchmarkDef)

            let runner = CheckRunner()
            let report = await runner.run(benchmark: filtered(benchmarkDef), level: level)

            CLIReporter.printReport(report, verbose: verbose)

            // Show diff from previous run
            if let prev = previousReport {
                let changed = report.results.filter { result in
                    let old = prev.results.first { $0.id == result.id }
                    return old?.status != result.status
                }
                if !changed.isEmpty {
                    print("  \(CLIReporter.bold)Changes since last scan:\(CLIReporter.reset)")
                    for c in changed {
                        let old = prev.results.first { $0.id == c.id }
                        let oldIcon = old.map { CLIReporter.icon(for: $0.status) } ?? "?"
                        let newIcon = CLIReporter.icon(for: c.status)
                        print("  \(oldIcon) → \(newIcon)  \(c.definition.title)")
                    }
                    print()
                }
            }

            print("  \(CLIReporter.dim)Next scan in \(interval)s — press Ctrl+C to stop\(CLIReporter.reset)")
            previousReport = report

            try await Task.sleep(for: .seconds(interval))
        }
    }

    private func filtered(_ benchmarkDef: BenchmarkDefinition) -> BenchmarkDefinition {
        var checks = benchmarkDef.checks

        if let cat = category, let category = CheckCategory(rawValue: cat) {
            checks = checks.filter { $0.category == category }
        }

        if let id = check {
            checks = checks.filter { $0.id == id }
        }

        return BenchmarkDefinition(
            name: benchmarkDef.name,
            version: benchmarkDef.version,
            platform: benchmarkDef.platform,
            description: benchmarkDef.description,
            checks: checks
        )
    }
}

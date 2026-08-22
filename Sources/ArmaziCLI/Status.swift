import ArgumentParser
import ArmaziCore

struct Status: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Quick status summary of your system security."
    )

    @Option(name: .shortAndLong, help: ProfileOption.help)
    var profile: String = BenchmarkProfile.cis.rawValue

    @Option(name: .shortAndLong, help: "CIS profile level (1 or 2).")
    var level: Int = 1

    func run() async throws {
        await ArmaziCLI.checkForUpdates()
        let selected = try ProfileOption.parse(profile)
        let benchmark = try BenchmarkParser.loadBundled(profile: selected)
        let runner = CheckRunner()
        let report = await runner.run(benchmark: benchmark, level: level)

        let score = Int(report.scorePercentage)
        let scoreColor = score >= 80 ? CLIReporter.green : (score >= 50 ? CLIReporter.yellow : CLIReporter.red)

        let platform = Platform.detect()

        print()
        print("  \(CLIReporter.bold)Armazi Security Status\(CLIReporter.reset)")
        print("  \(CLIReporter.dim)\(platform) — \(selected.displayName)\(CLIReporter.reset)")
        print()
        print("  \(scoreColor)\(CLIReporter.bold)\(score)%\(CLIReporter.reset) \(CLIReporter.dim)— \(report.passCount) passed, \(report.failCount) failed out of \(report.totalChecks) checks\(CLIReporter.reset)")
        print()

        for category in CheckCategory.allCases {
            let results = report.results(for: category)
            guard !results.isEmpty else { continue }
            let pass = results.filter { $0.status == .pass }.count
            let pct = Int(Double(pass) / Double(results.count) * 100)
            let color = pct >= 80 ? CLIReporter.green : (pct >= 50 ? CLIReporter.yellow : CLIReporter.red)
            let indicator = pct == 100 ? "\(CLIReporter.green)●\(CLIReporter.reset)" : "\(color)○\(CLIReporter.reset)"
            print("  \(indicator) \(category.displayName.padding(toLength: 22, withPad: " ", startingAt: 0)) \(color)\(pass)/\(results.count)\(CLIReporter.reset)")
        }
        print()

        if report.failCount > 0 || report.warningCount > 0 {
            let profileFlag = selected == .cis ? "" : " --profile \(selected.rawValue)"
            print("  \(CLIReporter.dim)Run \(CLIReporter.reset)armazi scan\(profileFlag) --verbose\(CLIReporter.dim) to see details and remediation steps.\(CLIReporter.reset)")
            print()
        }
    }
}

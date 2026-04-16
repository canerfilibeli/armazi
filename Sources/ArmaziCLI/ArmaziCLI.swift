import ArgumentParser
import ArmaziCore

@main
struct ArmaziCLI: AsyncParsableCommand {
    static let appVersion = "1.0.0"

    static let configuration = CommandConfiguration(
        commandName: "armazi",
        abstract: "macOS security auditor — scan your system against CIS Benchmarks.",
        version: appVersion,
        subcommands: [Scan.self, Status.self, ListChecks.self, Update.self, UpdateBenchmarks.self, Import.self],
        defaultSubcommand: Scan.self
    )

    /// Run update check before any subcommand executes.
    static func checkForUpdates() async {
        let result = await SelfUpdater.checkAndUpdate(currentVersion: appVersion)
        switch result {
        case .upToDate:
            break
        case .updated(let version):
            print("  \(CLIReporter.green)Updated to v\(version). Please re-run your command.\(CLIReporter.reset)")
        case .skipped(let reason):
            print("  \(CLIReporter.dim)Skipping update: \(reason)\(CLIReporter.reset)")
        }
    }
}

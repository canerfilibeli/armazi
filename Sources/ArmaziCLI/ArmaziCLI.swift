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

    /// Check for new version (notify only, never auto-install).
    static func checkForUpdates() async {
        let result = await SelfUpdater.checkForUpdate(currentVersion: appVersion)
        switch result {
        case .upToDate:
            break
        case .available(let version):
            print("  \(CLIReporter.yellow)New version available: v\(version). Run \(CLIReporter.reset)armazi update\(CLIReporter.yellow) to install.\(CLIReporter.reset)")
        case .updated, .skipped:
            break
        }
    }
}

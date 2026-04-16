import ArgumentParser
import ArmaziCore

struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Check for updates and install the latest version."
    )

    func run() async throws {
        print()
        print("  \(CLIReporter.bold)Checking for updates...\(CLIReporter.reset)")

        // First check if update is available
        let checkResult = await SelfUpdater.checkForUpdate(currentVersion: ArmaziCLI.appVersion)
        switch checkResult {
        case .upToDate:
            print("  \(CLIReporter.green)Already up to date (v\(ArmaziCLI.appVersion)).\(CLIReporter.reset)")
            print()
            return
        case .available(let version):
            print("  \(CLIReporter.yellow)New version available: v\(version)\(CLIReporter.reset)")
            print("  Installing...")
        case .skipped(let reason):
            print("  \(CLIReporter.yellow)\(reason)\(CLIReporter.reset)")
        case .updated:
            print()
            return
        }

        // Install with checksum verification
        let installResult = await SelfUpdater.installUpdate(currentVersion: ArmaziCLI.appVersion)
        switch installResult {
        case .updated(let version):
            print("  \(CLIReporter.green)Updated to v\(version). Please re-run your command.\(CLIReporter.reset)")
        case .skipped(let reason):
            print("  \(CLIReporter.red)Update failed: \(reason)\(CLIReporter.reset)")
        case .upToDate, .available:
            break
        }
        print()
    }
}

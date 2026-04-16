import ArgumentParser
import ArmaziCore

struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Check for updates and install the latest version."
    )

    func run() async throws {
        print()
        print("  \(CLIReporter.bold)Checking for updates...\(CLIReporter.reset)")

        let result = await SelfUpdater.checkAndUpdate(currentVersion: ArmaziCLI.appVersion)
        switch result {
        case .upToDate:
            print("  \(CLIReporter.green)Already up to date (v\(ArmaziCLI.appVersion)).\(CLIReporter.reset)")
        case .updated(let version):
            print("  \(CLIReporter.green)Updated to v\(version). Please re-run your command.\(CLIReporter.reset)")
        case .skipped(let reason):
            print("  \(CLIReporter.yellow)Could not update: \(reason)\(CLIReporter.reset)")
        }
        print()
    }
}

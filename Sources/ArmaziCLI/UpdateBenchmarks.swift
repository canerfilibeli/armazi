import ArgumentParser
import ArmaziCore

struct UpdateBenchmarks: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update-benchmarks",
        abstract: "Download the latest benchmark files from GitHub."
    )

    func run() async throws {
        print()
        print("  \(CLIReporter.bold)Updating benchmarks...\(CLIReporter.reset)")
        print("  \(CLIReporter.dim)Source: github.com/canerfilibeli/armazi\(CLIReporter.reset)")
        print()

        let result = await BenchmarkUpdater.update()
        switch result {
        case .updated(let files):
            print("  \(CLIReporter.green)Updated \(files.count) file(s):\(CLIReporter.reset)")
            for file in files {
                print("    \(CLIReporter.green)✓\(CLIReporter.reset) \(file)")
            }
            print()
            print("  \(CLIReporter.dim)Saved to: ~/.config/armazi/benchmarks/\(CLIReporter.reset)")

        case .upToDate:
            print("  \(CLIReporter.green)Benchmarks are up to date.\(CLIReporter.reset)")

        case .failed(let reason):
            print("  \(CLIReporter.red)Failed: \(reason)\(CLIReporter.reset)")
        }
        print()
    }
}

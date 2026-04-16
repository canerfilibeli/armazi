import ArgumentParser
import ArmaziCore

struct UpdateBenchmarks: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update-benchmarks",
        abstract: "Download the latest benchmark files for your platform."
    )

    func run() async throws {
        let platform = Platform.detect()

        print()
        print("  \(CLIReporter.bold)Updating benchmarks...\(CLIReporter.reset)")
        print("  \(CLIReporter.dim)Detected: \(platform)\(CLIReporter.reset)")

        let sources = BenchmarkRegistry.availableSources(for: platform)
        if !sources.isEmpty {
            print("  \(CLIReporter.dim)Sources:\(CLIReporter.reset)")
            for source in sources {
                print("    \(CLIReporter.dim)• \(source.name) (\(source.license))\(CLIReporter.reset)")
            }
        }
        print()

        let result = await BenchmarkRegistry.fetchBenchmarks(for: platform)
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

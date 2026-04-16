import ArgumentParser
import Foundation
import ArmaziCore

struct Import: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Convert a CIS XCCDF (XML) benchmark to Armazi YAML format."
    )

    @Argument(help: "Path to the XCCDF XML file.")
    var input: String

    @Option(name: .shortAndLong, help: "Output file path. Defaults to same name with .yaml extension.")
    var output: String?

    @Option(name: .shortAndLong, help: "Benchmark name.")
    var name: String?

    @Option(name: .long, help: "Target platform (default: macOS).")
    var platform: String = "macOS"

    @Flag(name: .long, help: "Install the converted benchmark to ~/.config/armazi/benchmarks/.")
    var install: Bool = false

    func run() async throws {
        let inputURL = URL(fileURLWithPath: input)

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            print("  \(CLIReporter.red)File not found: \(input)\(CLIReporter.reset)")
            throw ExitCode.failure
        }

        print()
        print("  \(CLIReporter.bold)Importing XCCDF benchmark...\(CLIReporter.reset)")
        print("  \(CLIReporter.dim)Source: \(inputURL.lastPathComponent)\(CLIReporter.reset)")

        let yaml: String
        do {
            yaml = try XCCDFImporter.importFile(at: inputURL, name: name, platform: platform)
        } catch {
            print("  \(CLIReporter.red)Import failed: \(error.localizedDescription)\(CLIReporter.reset)")
            throw ExitCode.failure
        }

        // Determine output path
        let outputURL: URL
        if let output {
            outputURL = URL(fileURLWithPath: output)
        } else {
            outputURL = inputURL.deletingPathExtension().appendingPathExtension("yaml")
        }

        try yaml.write(to: outputURL, atomically: true, encoding: .utf8)
        print("  \(CLIReporter.green)✓\(CLIReporter.reset) Saved to: \(outputURL.path)")

        // Validate the generated YAML
        do {
            let benchmark = try BenchmarkParser.parse(yaml: yaml)
            print("  \(CLIReporter.green)✓\(CLIReporter.reset) Valid benchmark: \(benchmark.checks.count) checks found")
        } catch {
            print("  \(CLIReporter.yellow)⚠ Generated YAML may need manual review: \(error.localizedDescription)\(CLIReporter.reset)")
        }

        // Install if requested
        if install {
            let localDir = BenchmarkParser.localDir
            try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)
            let dest = localDir.appendingPathComponent(outputURL.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: outputURL, to: dest)
            print("  \(CLIReporter.green)✓\(CLIReporter.reset) Installed to: \(dest.path)")
        }

        print()
    }
}

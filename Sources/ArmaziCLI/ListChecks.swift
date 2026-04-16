import ArgumentParser
import Foundation
import ArmaziCore

struct ListChecks: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available checks in the benchmark."
    )

    @Option(name: .shortAndLong, help: "Path to a custom benchmark YAML file.")
    var benchmark: String?

    @Option(name: .shortAndLong, help: "CIS profile level (1 or 2).")
    var level: Int = 1

    func run() async throws {
        let benchmarkDef: BenchmarkDefinition
        if let path = benchmark {
            benchmarkDef = try BenchmarkParser.parse(fileURL: URL(fileURLWithPath: path))
        } else {
            benchmarkDef = try BenchmarkParser.loadBundled()
        }

        let total = benchmarkDef.checks.filter { $0.level <= level }.count
        print()
        print("  \(CLIReporter.bold)\(benchmarkDef.name)\(CLIReporter.reset) v\(benchmarkDef.version) — \(total) checks (Level ≤ \(level))")
        print()

        CLIReporter.printCheckList(benchmarkDef, level: level)
    }
}

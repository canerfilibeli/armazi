import ArgumentParser

@main
struct ArmaziCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "armazi",
        abstract: "macOS security auditor — scan your system against CIS Benchmarks.",
        version: "1.0.0",
        subcommands: [Scan.self, Status.self, ListChecks.self],
        defaultSubcommand: Scan.self
    )
}

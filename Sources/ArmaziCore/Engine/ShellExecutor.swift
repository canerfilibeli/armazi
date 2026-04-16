import Foundation

/// Executes shell commands and returns their output.
public enum ShellExecutor {
    public struct Result: Sendable {
        public let output: String
        public let exitCode: Int32
    }

    /// Runs a shell command asynchronously and returns its output and exit code.
    public static func run(_ command: String) async -> Result {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stdout = Pipe()
                let stderr = Pipe()

                process.executableURL = URL(fileURLWithPath: "/bin/sh")
                process.arguments = ["-c", command]
                process.standardOutput = stdout
                process.standardError = stderr

                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    continuation.resume(returning: Result(output: error.localizedDescription, exitCode: -1))
                    return
                }

                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()

                let outStr = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                let combined = outStr.isEmpty ? errStr : outStr
                continuation.resume(returning: Result(output: combined, exitCode: process.terminationStatus))
            }
        }
    }

    /// Runs multiple commands with administrator privileges in a single batch.
    /// Shows the macOS authorization dialog once, then executes all commands.
    /// Returns a dictionary mapping check IDs to their results.
    public static func runElevatedBatch(_ commands: [(id: String, command: String)]) async -> [String: Result] {
        guard !commands.isEmpty else { return [:] }

        let startMarker = "<<<ARMAZI:"
        let exitMarker = "<<<ARMAZI_EXIT:"
        let endMarker = ">>>"

        // Build a batch script with markers between each command's output
        var script = "#!/bin/bash\n"
        for (id, command) in commands {
            script += "echo '\(startMarker)\(id)\(endMarker)'\n"
            script += "\(command) 2>&1\n"
            script += "echo '\(exitMarker)\(id):'$?'\(endMarker)'\n"
        }

        // Write to a temp file
        let pid = ProcessInfo.processInfo.processIdentifier
        let tempPath = "/tmp/armazi_elevated_\(pid).sh"
        do {
            try script.write(toFile: tempPath, atomically: true, encoding: .utf8)
        } catch {
            return commands.reduce(into: [:]) { $0[$1.id] = Result(output: "Failed to create temp script", exitCode: -1) }
        }

        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        // Run via osascript with administrator privileges (one password prompt)
        let osascript = "osascript -e 'do shell script \"bash " + tempPath + "\" with administrator privileges'"
        let batchResult = await run(osascript)

        // Parse output by markers
        return parseElevatedOutput(batchResult.output, commands: commands, startMarker: startMarker, exitMarker: exitMarker, endMarker: endMarker)
    }

    private static func parseElevatedOutput(
        _ output: String,
        commands: [(id: String, command: String)],
        startMarker: String,
        exitMarker: String,
        endMarker: String
    ) -> [String: Result] {
        var results: [String: Result] = [:]
        let lines = output.components(separatedBy: "\n")

        var currentID: String?
        var currentOutput: [String] = []

        for line in lines {
            if line.hasPrefix(startMarker) && line.hasSuffix(endMarker) {
                // Save previous check's output
                if let id = currentID {
                    results[id] = Result(output: currentOutput.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), exitCode: 0)
                }
                let id = String(line.dropFirst(startMarker.count).dropLast(endMarker.count))
                currentID = id
                currentOutput = []
            } else if line.hasPrefix(exitMarker) && line.hasSuffix(endMarker) {
                let payload = String(line.dropFirst(exitMarker.count).dropLast(endMarker.count))
                let parts = payload.split(separator: ":", maxSplits: 1)
                if parts.count == 2, let id = currentID, String(parts[0]) == id {
                    let exitCode = Int32(parts[1].trimmingCharacters(in: .punctuationCharacters)) ?? 0
                    results[id] = Result(
                        output: currentOutput.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines),
                        exitCode: exitCode
                    )
                }
                currentID = nil
                currentOutput = []
            } else if currentID != nil {
                currentOutput.append(line)
            }
        }

        // Handle any remaining output
        if let id = currentID {
            results[id] = Result(output: currentOutput.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), exitCode: 0)
        }

        // Fill in missing results
        for (id, _) in commands where results[id] == nil {
            results[id] = Result(output: "No output captured", exitCode: -1)
        }

        return results
    }
}

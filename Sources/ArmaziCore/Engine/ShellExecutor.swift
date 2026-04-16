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

                // Read pipe data BEFORE waitUntilExit to prevent pipe deadlock (L5)
                var outData = Data()
                var errData = Data()

                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: Result(output: error.localizedDescription, exitCode: -1))
                    return
                }

                outData = stdout.fileHandleForReading.readDataToEndOfFile()
                errData = stderr.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                let outStr = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errStr = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                let combined = outStr.isEmpty ? errStr : outStr
                continuation.resume(returning: Result(output: combined, exitCode: process.terminationStatus))
            }
        }
    }

    /// Sanitize a check ID to prevent shell injection (C2).
    /// Only allows alphanumeric characters, dots, and hyphens.
    private static func sanitizeID(_ id: String) -> String {
        String(id.unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0) || $0 == "." || $0 == "-" || $0 == "_"
        })
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
            let safeID = sanitizeID(id)
            script += "echo '\(startMarker)\(safeID)\(endMarker)'\n"
            script += "\(command) 2>&1\n"
            script += "echo '\(exitMarker)\(safeID):'$?'\(endMarker)'\n"
        }

        // Write to a secure temp file (H2: unpredictable path, restrictive permissions)
        let tempDir = FileManager.default.temporaryDirectory
        let tempPath = tempDir.appendingPathComponent("armazi_\(UUID().uuidString).sh").path

        let fm = FileManager.default
        guard fm.createFile(
            atPath: tempPath,
            contents: script.data(using: .utf8),
            attributes: [.posixPermissions: 0o700]
        ) else {
            return commands.reduce(into: [:]) { $0[$1.id] = Result(output: "Failed to create temp script", exitCode: -1) }
        }

        defer { try? fm.removeItem(atPath: tempPath) }

        // Verify it's a regular file, not a symlink (H2)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: tempPath, isDirectory: &isDir),
              !isDir.boolValue else {
            return commands.reduce(into: [:]) { $0[$1.id] = Result(output: "Temp file validation failed", exitCode: -1) }
        }

        // Run via osascript with administrator privileges (one password prompt)
        let escapedPath = tempPath.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "'", with: "'\\''")
        let osascript = "osascript -e 'do shell script \"bash \\\"\(escapedPath)\\\"\" with administrator privileges'"
        let batchResult = await run(osascript)

        // Parse output by markers (use sanitized IDs for lookup)
        let idMap = Dictionary(uniqueKeysWithValues: commands.map { ($0.id, sanitizeID($0.id)) })
        let parsed = parseElevatedOutput(batchResult.output, commands: commands.map { (sanitizeID($0.id), $0.command) },
                                          startMarker: startMarker, exitMarker: exitMarker, endMarker: endMarker)

        // Map back to original IDs
        var results: [String: Result] = [:]
        for (origID, safeID) in idMap {
            results[origID] = parsed[safeID] ?? Result(output: "No output captured", exitCode: -1)
        }
        return results
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

        if let id = currentID {
            results[id] = Result(output: currentOutput.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), exitCode: 0)
        }

        for (id, _) in commands where results[id] == nil {
            results[id] = Result(output: "No output captured", exitCode: -1)
        }

        return results
    }
}

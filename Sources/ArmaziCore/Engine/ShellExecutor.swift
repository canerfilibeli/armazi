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
}

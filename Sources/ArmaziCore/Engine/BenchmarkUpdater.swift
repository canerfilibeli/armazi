import Foundation

/// Downloads latest benchmark YAML files from GitHub.
public enum BenchmarkUpdater {
    private static let repo = "canerfilibeli/armazi"
    private static let branch = "main"
    private static let benchmarkPath = "Sources/ArmaziCore/Benchmarks"

    /// Allowed filename pattern: alphanumeric, hyphens, underscores, dots.
    private static func isSafeFilename(_ name: String) -> Bool {
        name.range(of: #"^[a-zA-Z0-9._-]+\.(yaml|yml)$"#, options: .regularExpression) != nil
    }

    public enum UpdateResult: Sendable {
        case updated([String])
        case upToDate
        case failed(String)
    }

    /// Fetch the latest benchmark files from GitHub and save to ~/.config/armazi/benchmarks/.
    public static func update(timeout: TimeInterval = 15) async -> UpdateResult {
        let contentsURL = "https://api.github.com/repos/\(repo)/contents/\(benchmarkPath)?ref=\(branch)"
        guard let url = URL(string: contentsURL) else { return .failed("Invalid URL") }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            return .failed("No internet connection")
        }

        guard let files = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return .failed("Could not parse GitHub API response")
        }

        let yamlFiles = files.filter {
            let name = $0["name"] as? String ?? ""
            return name.hasSuffix(".yaml") || name.hasSuffix(".yml")
        }

        guard !yamlFiles.isEmpty else { return .failed("No benchmark files found in repository") }

        let localDir = BenchmarkParser.localDir
        try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)

        var updated: [String] = []
        for file in yamlFiles {
            guard let downloadURL = file["download_url"] as? String,
                  let name = file["name"] as? String,
                  let remoteURL = URL(string: downloadURL) else { continue }

            // Path traversal protection (H4): validate filename
            let safeName = URL(fileURLWithPath: name).lastPathComponent
            guard isSafeFilename(safeName) else { continue }

            // Enforce HTTPS (M3)
            guard remoteURL.scheme == "https" else { continue }

            do {
                let (fileData, _) = try await URLSession.shared.data(from: remoteURL)
                let newContent = String(data: fileData, encoding: .utf8) ?? ""

                // Validate it's parseable YAML before saving (H3)
                _ = try BenchmarkParser.parse(yaml: newContent)

                let dest = localDir.appendingPathComponent(safeName)
                let existing = try? String(contentsOf: dest, encoding: .utf8)

                if existing != newContent {
                    try fileData.write(to: dest)
                    updated.append(safeName)
                }
            } catch {
                continue
            }
        }

        return updated.isEmpty ? .upToDate : .updated(updated)
    }
}

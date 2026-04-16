import Foundation

/// Maps platforms to their benchmark sources and manages auto-selection.
public enum BenchmarkRegistry {

    /// Open-source benchmark sources by platform.
    public struct Source: Sendable {
        public let name: String
        public let repo: String
        public let path: String
        public let format: Format
        public let license: String

        public enum Format: Sendable {
            case armaziYAML
            case xccdf
        }
    }

    /// Known open-source benchmark sources.
    public static let sources: [Platform.OS: [Source]] = [
        .macOS: [
            Source(
                name: "Armazi CIS macOS Benchmark",
                repo: "canerfilibeli/armazi",
                path: "Sources/ArmaziCore/Benchmarks",
                format: .armaziYAML,
                license: "MIT"
            ),
            Source(
                name: "NIST macOS Security Compliance Project",
                repo: "usnistgov/macos_security",
                path: "baselines",
                format: .armaziYAML,
                license: "Public Domain (NIST)"
            ),
        ],
        .ubuntu: [
            Source(
                name: "ComplianceAsCode Ubuntu",
                repo: "ComplianceAsCode/content",
                path: "products/ubuntu2404/profiles",
                format: .xccdf,
                license: "BSD-3-Clause"
            ),
        ],
        .debian: [
            Source(
                name: "ComplianceAsCode Debian",
                repo: "ComplianceAsCode/content",
                path: "products/debian12/profiles",
                format: .xccdf,
                license: "BSD-3-Clause"
            ),
        ],
        .rhel: [
            Source(
                name: "ComplianceAsCode RHEL",
                repo: "ComplianceAsCode/content",
                path: "products/rhel9/profiles",
                format: .xccdf,
                license: "BSD-3-Clause"
            ),
        ],
        .fedora: [
            Source(
                name: "ComplianceAsCode Fedora",
                repo: "ComplianceAsCode/content",
                path: "products/fedora/profiles",
                format: .xccdf,
                license: "BSD-3-Clause"
            ),
        ],
    ]

    /// Get the best benchmark for the current platform.
    public static func loadForCurrentPlatform() throws -> BenchmarkDefinition {
        let platform = Platform.detect()

        // 1. Check for local override matching this platform
        let localFile = BenchmarkParser.localDir
            .appendingPathComponent("\(platform.benchmarkID)-benchmark.yaml")
        if FileManager.default.fileExists(atPath: localFile.path) {
            return try BenchmarkParser.parse(fileURL: localFile)
        }

        // 2. Check for any local file matching the OS
        let localFiles = BenchmarkParser.listLocal()
        if let match = localFiles.first(where: { $0.contains(platform.benchmarkID) }) {
            let url = BenchmarkParser.localDir.appendingPathComponent(match + ".yaml")
            return try BenchmarkParser.parse(fileURL: url)
        }

        // 3. Fall back to embedded default (macOS only for now)
        if platform.os == .macOS {
            return try BenchmarkParser.parse(yaml: EmbeddedBenchmarks.cisMacOS)
        }

        throw BenchmarkError.bundledFileNotFound(
            "No benchmark found for \(platform.description). Run 'armazi update-benchmarks' to download one."
        )
    }

    /// List available sources for the detected platform.
    public static func availableSources(for platform: Platform) -> [Source] {
        sources[platform.os] ?? []
    }

    /// Fetch benchmarks for a specific platform from open-source repositories.
    public static func fetchBenchmarks(for platform: Platform, timeout: TimeInterval = 30) async -> BenchmarkUpdater.UpdateResult {
        // Always fetch from Armazi's own repo first
        let armaziResult = await BenchmarkUpdater.update(timeout: timeout)

        // For non-macOS, also try ComplianceAsCode
        if platform.os != .macOS, let source = sources[platform.os]?.first {
            let ccResult = await fetchFromComplianceAsCode(
                platform: platform,
                source: source,
                timeout: timeout
            )
            switch (armaziResult, ccResult) {
            case (.updated(let a), .updated(let b)):
                return .updated(a + b)
            case (.updated(let files), _), (_, .updated(let files)):
                return .updated(files)
            case (.failed(let r1), .failed(let r2)):
                return .failed("\(r1); \(r2)")
            default:
                return armaziResult
            }
        }

        return armaziResult
    }

    /// Fetch XCCDF benchmarks from ComplianceAsCode and convert to YAML.
    private static func fetchFromComplianceAsCode(
        platform: Platform,
        source: Source,
        timeout: TimeInterval
    ) async -> BenchmarkUpdater.UpdateResult {
        let apiURL = "https://api.github.com/repos/\(source.repo)/contents/\(source.path)?ref=master"
        guard let url = URL(string: apiURL) else { return .failed("Invalid URL") }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let files = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return .failed("Could not fetch ComplianceAsCode profiles")
        }

        let localDir = BenchmarkParser.localDir
        try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)

        var updated: [String] = []
        for file in files {
            guard let name = file["name"] as? String,
                  let downloadURL = file["download_url"] as? String,
                  let remoteURL = URL(string: downloadURL),
                  remoteURL.scheme == "https",
                  name.hasSuffix(".profile") || name.hasSuffix(".xml") else { continue }

            guard let (fileData, _) = try? await URLSession.shared.data(from: remoteURL),
                  let content = String(data: fileData, encoding: .utf8) else { continue }

            let yamlName = "\(platform.benchmarkID)-\(name.replacingOccurrences(of: ".profile", with: "")).yaml"
            let dest = localDir.appendingPathComponent(yamlName)

            // For XCCDF XML files, try to convert
            if name.hasSuffix(".xml") {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xml")
                try? content.write(to: tempURL, atomically: true, encoding: .utf8)
                defer { try? FileManager.default.removeItem(at: tempURL) }

                if let yaml = try? XCCDFImporter.importFile(at: tempURL, name: "\(platform.benchmarkID) CIS", platform: platform.os.rawValue) {
                    try? yaml.write(to: dest, atomically: true, encoding: .utf8)
                    updated.append(yamlName)
                }
            } else {
                // Save profile files directly for reference
                try? fileData.write(to: dest)
                updated.append(yamlName)
            }
        }

        return updated.isEmpty ? .upToDate : .updated(updated)
    }
}

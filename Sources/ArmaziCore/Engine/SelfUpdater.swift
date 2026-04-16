import Foundation

/// Checks GitHub for new releases and notifies the user.
/// Does NOT auto-install — requires explicit confirmation via `armazi update`.
public enum SelfUpdater {
    private static let repo = "canerfilibeli/armazi"
    private static let apiURL = "https://api.github.com/repos/\(repo)/releases/latest"

    public enum UpdateResult: Sendable {
        case upToDate
        case available(String)
        case updated(String)
        case skipped(String)
    }

    /// Check if a newer version is available (does not install).
    public static func checkForUpdate(currentVersion: String, timeout: TimeInterval = 5) async -> UpdateResult {
        guard let releaseInfo = await fetchLatestRelease(timeout: timeout) else {
            return .skipped("Could not check for updates")
        }

        let latestVersion = releaseInfo.version
        guard latestVersion != currentVersion else {
            return .upToDate
        }

        return .available(latestVersion)
    }

    /// Download and install the latest version with checksum verification.
    public static func installUpdate(currentVersion: String, timeout: TimeInterval = 30) async -> UpdateResult {
        guard let releaseInfo = await fetchLatestRelease(timeout: timeout) else {
            return .skipped("Could not fetch release info")
        }

        guard releaseInfo.version != currentVersion else {
            return .upToDate
        }

        // Download the binary
        guard let assetURL = releaseInfo.binaryURL else {
            return .skipped("No compatible binary found in release")
        }

        let newBinary: Data
        do {
            (newBinary, _) = try await URLSession.shared.data(from: assetURL)
        } catch {
            return .skipped("Failed to download update")
        }

        // Minimum size sanity check (C3)
        guard newBinary.count > 100_000 else {
            return .skipped("Downloaded file too small — possibly corrupt")
        }

        // Verify SHA-256 checksum if available (C3)
        if let checksumURL = releaseInfo.checksumURL {
            do {
                let (checksumData, _) = try await URLSession.shared.data(from: checksumURL)
                let checksumContent = String(data: checksumData, encoding: .utf8) ?? ""
                let expectedHash = checksumContent.components(separatedBy: .whitespaces).first ?? ""

                let actualHash = sha256(data: newBinary)
                guard actualHash == expectedHash else {
                    return .skipped("Checksum mismatch: expected \(expectedHash.prefix(12))..., got \(actualHash.prefix(12))...")
                }
            } catch {
                return .skipped("Could not verify checksum")
            }
        }

        // Get the real executable path (M2: use _NSGetExecutablePath instead of argv[0])
        let resolvedPath = realExecutablePath()
        guard !resolvedPath.isEmpty else {
            return .skipped("Could not determine executable path")
        }

        // Atomic binary replacement (H1: use replaceItemAt for atomic swap)
        do {
            let tempURL = URL(fileURLWithPath: resolvedPath + ".update-\(UUID().uuidString)")
            try newBinary.write(to: tempURL)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempURL.path)

            _ = try FileManager.default.replaceItemAt(
                URL(fileURLWithPath: resolvedPath),
                withItemAt: tempURL
            )

            return .updated(releaseInfo.version)
        } catch {
            return .skipped("Failed to install update: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private struct ReleaseInfo {
        let version: String
        let binaryURL: URL?
        let checksumURL: URL?
    }

    private static func fetchLatestRelease(timeout: TimeInterval) async -> ReleaseInfo? {
        guard let url = URL(string: apiURL) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String,
              let assets = json["assets"] as? [[String: Any]] else {
            return nil
        }

        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

        let binaryAsset = assets.first { ($0["name"] as? String)?.contains("macos-arm64") == true }
        let checksumAsset = assets.first { ($0["name"] as? String) == "checksums.txt" }

        // Enforce HTTPS on download URLs (M3)
        let binaryURL = (binaryAsset?["browser_download_url"] as? String)
            .flatMap { $0.hasPrefix("https://") ? URL(string: $0) : nil }
        let checksumURL = (checksumAsset?["browser_download_url"] as? String)
            .flatMap { $0.hasPrefix("https://") ? URL(string: $0) : nil }

        return ReleaseInfo(version: version, binaryURL: binaryURL, checksumURL: checksumURL)
    }

    private static func realExecutablePath() -> String {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        var size = UInt32(MAXPATHLEN)
        guard _NSGetExecutablePath(&buffer, &size) == 0 else { return "" }
        return FileManager.default.string(withFileSystemRepresentation: buffer, length: strlen(buffer))
    }

    private static func sha256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto

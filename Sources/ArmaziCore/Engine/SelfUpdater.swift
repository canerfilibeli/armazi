import Foundation

/// Checks GitHub for new releases and updates the binary in-place.
public enum SelfUpdater {
    private static let repo = "canerfilibeli/armazi"
    private static let apiURL = "https://api.github.com/repos/\(repo)/releases/latest"

    public enum UpdateResult: Sendable {
        case upToDate
        case updated(String)
        case skipped(String)
    }

    /// Check for updates and auto-update if a newer version is available.
    /// Returns immediately with .skipped if offline or on error.
    public static func checkAndUpdate(currentVersion: String, timeout: TimeInterval = 5) async -> UpdateResult {
        guard let url = URL(string: apiURL) else { return .skipped("Invalid API URL") }

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            return .skipped("No internet connection")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String,
              let assets = json["assets"] as? [[String: Any]] else {
            return .skipped("Could not parse release info")
        }

        let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

        guard latestVersion != currentVersion else {
            return .upToDate
        }

        // Find the arm64 binary asset
        guard let asset = assets.first(where: { ($0["name"] as? String)?.contains("macos-arm64") == true }),
              let downloadURL = asset["browser_download_url"] as? String,
              let assetURL = URL(string: downloadURL) else {
            return .skipped("No compatible binary found in release")
        }

        // Download the new binary
        let newBinary: Data
        do {
            (newBinary, _) = try await URLSession.shared.data(from: assetURL)
        } catch {
            return .skipped("Failed to download update")
        }

        // Find current executable path and replace it
        let executablePath = ProcessInfo.processInfo.arguments[0]
        let resolvedPath: String
        if executablePath.hasPrefix("/") {
            resolvedPath = executablePath
        } else {
            resolvedPath = FileManager.default.currentDirectoryPath + "/" + executablePath
        }

        do {
            let tempPath = resolvedPath + ".update"
            try newBinary.write(to: URL(fileURLWithPath: tempPath))

            // Make executable
            let attrs: [FileAttributeKey: Any] = [.posixPermissions: 0o755]
            try FileManager.default.setAttributes(attrs, ofItemAtPath: tempPath)

            // Atomic replace
            let backupPath = resolvedPath + ".backup"
            try? FileManager.default.removeItem(atPath: backupPath)
            try FileManager.default.moveItem(atPath: resolvedPath, toPath: backupPath)
            try FileManager.default.moveItem(atPath: tempPath, toPath: resolvedPath)
            try? FileManager.default.removeItem(atPath: backupPath)

            return .updated(latestVersion)
        } catch {
            return .skipped("Failed to install update: \(error.localizedDescription)")
        }
    }
}

import Foundation

/// Represents a detected operating system and version.
public struct Platform: Sendable, CustomStringConvertible {
    public let os: OS
    public let version: String
    public let majorVersion: Int
    public let name: String
    public let arch: String

    public enum OS: String, Sendable {
        case macOS
        case ubuntu
        case debian
        case rhel
        case fedora
        case amazonLinux = "amazon_linux"
        case suse
        case windows
        case unknown
    }

    public var description: String {
        "\(name) \(version) (\(arch))"
    }

    /// Benchmark filename for this platform (e.g., "macos-15", "ubuntu-24.04")
    public var benchmarkID: String {
        switch os {
        case .macOS:
            return "macos-\(majorVersion)"
        case .ubuntu, .debian:
            return "\(os.rawValue)-\(version)"
        case .rhel:
            return "rhel-\(majorVersion)"
        case .fedora:
            return "fedora-\(majorVersion)"
        case .amazonLinux:
            return "amazon-linux-\(version)"
        case .suse:
            return "suse-\(majorVersion)"
        case .windows:
            return "windows-\(majorVersion)"
        case .unknown:
            return "unknown"
        }
    }

    /// Detect the current platform.
    public static func detect() -> Platform {
        let arch = detectArch()

        #if os(macOS)
        return detectMacOS(arch: arch)
        #elseif os(Linux)
        return detectLinux(arch: arch)
        #elseif os(Windows)
        return detectWindows(arch: arch)
        #else
        return Platform(os: .unknown, version: "0", majorVersion: 0, name: "Unknown", arch: arch)
        #endif
    }

    private static func detectArch() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }

    #if os(macOS)
    private static func detectMacOS(arch: String) -> Platform {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        // macOS version numbers: 13=Ventura, 14=Sonoma, 15=Sequoia, 26=Tahoe(?)
        let name: String
        switch version.majorVersion {
        case 26: name = "macOS Tahoe"
        case 15: name = "macOS Sequoia"
        case 14: name = "macOS Sonoma"
        case 13: name = "macOS Ventura"
        default: name = "macOS"
        }

        return Platform(
            os: .macOS,
            version: versionString,
            majorVersion: version.majorVersion,
            name: name,
            arch: arch
        )
    }
    #endif

    #if os(Linux)
    private static func detectLinux(arch: String) -> Platform {
        // Parse /etc/os-release
        guard let content = try? String(contentsOfFile: "/etc/os-release", encoding: .utf8) else {
            return Platform(os: .unknown, version: "0", majorVersion: 0, name: "Linux", arch: arch)
        }

        var fields: [String: String] = [:]
        for line in content.components(separatedBy: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let value = String(parts[1]).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            fields[key] = value
        }

        let id = fields["ID"] ?? "linux"
        let versionID = fields["VERSION_ID"] ?? "0"
        let prettyName = fields["PRETTY_NAME"] ?? "Linux"
        let major = Int(versionID.split(separator: ".").first ?? "0") ?? 0

        let os: OS
        switch id {
        case "ubuntu": os = .ubuntu
        case "debian": os = .debian
        case "rhel", "centos", "rocky", "almalinux", "ol": os = .rhel
        case "fedora": os = .fedora
        case "amzn": os = .amazonLinux
        case "sles", "opensuse-leap", "opensuse-tumbleweed": os = .suse
        default: os = .unknown
        }

        return Platform(os: os, version: versionID, majorVersion: major, name: prettyName, arch: arch)
    }
    #endif

    #if os(Windows)
    private static func detectWindows(arch: String) -> Platform {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let major = version.majorVersion
        let build = version.patchVersion

        let name: String
        if major >= 10 && build >= 22000 {
            name = "Windows 11"
        } else {
            name = "Windows 10"
        }

        return Platform(
            os: .windows,
            version: "\(major).\(version.minorVersion).\(build)",
            majorVersion: build >= 22000 ? 11 : 10,
            name: name,
            arch: arch
        )
    }
    #endif
}

import XCTest
@testable import ArmaziCore

final class PersonalProtectionTests: XCTestCase {

    private func personalBenchmark() throws -> BenchmarkDefinition {
        try BenchmarkParser.parse(yaml: EmbeddedBenchmarks.personalProtectionMacOS)
    }

    /// Repository root, derived from this file's location.
    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // ArmaziTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repo root
    }

    func testPersonalProfileParses() throws {
        let benchmark = try personalBenchmark()
        XCTAssertEqual(benchmark.name, "Armazi Personal Protection")
        XCTAssertEqual(benchmark.platform, "macOS")
        XCTAssertFalse(benchmark.checks.isEmpty)
    }

    func testPersonalProfileCoversEveryConsumerCategory() throws {
        let categories = Set(try personalBenchmark().checks.map(\.category))
        for expected in [
            CheckCategory.identityProtection,
            .dataProtection,
            .onlineSafety,
            .homeNetwork,
            .privacy,
        ] {
            XCTAssertTrue(categories.contains(expected), "No checks for \(expected.rawValue)")
        }
    }

    func testCheckIDsAreUniqueAndWellFormed() throws {
        var seen = Set<String>()
        for check in try personalBenchmark().checks {
            XCTAssertTrue(check.id.hasPrefix("P"), "Personal check IDs are P-prefixed: \(check.id)")
            XCTAssertTrue(seen.insert(check.id).inserted, "Duplicate check ID: \(check.id)")
            XCTAssertFalse(check.title.isEmpty, "Empty title for \(check.id)")
            XCTAssertFalse(check.description.isEmpty, "Empty description for \(check.id)")
            XCTAssertFalse(check.audit.command.isEmpty, "Empty audit command for \(check.id)")
            XCTAssertNotNil(check.remediation, "Missing remediation for \(check.id)")
            XCTAssertGreaterThanOrEqual(check.level, 1, "Bad level for \(check.id)")
        }
    }

    /// Checks that echo their own verdict must be able to print the token
    /// the match rule looks for, otherwise they can never pass.
    func testScriptedChecksCanEmitTheirMatchValue() throws {
        for check in try personalBenchmark().checks {
            guard case .contains(let expected) = check.audit.match,
                  check.audit.command.contains("echo") else { continue }
            XCTAssertTrue(
                check.audit.command.contains(expected),
                "\(check.id) matches on '\(expected)' but never prints it"
            )
        }
    }

    func testProfilesLoadDistinctBenchmarks() throws {
        let cis = try BenchmarkParser.parse(yaml: EmbeddedBenchmarks.cisMacOS)
        let personal = try personalBenchmark()
        XCTAssertNotEqual(cis.name, personal.name)

        let cisCategories = Set(cis.checks.map(\.category))
        XCTAssertFalse(cisCategories.contains(.identityProtection))
        XCTAssertFalse(cisCategories.contains(.privacy))
    }

    /// The embedded literals are generated from the YAML by
    /// Scripts/embed-benchmarks.py — this catches a stale regeneration.
    func testEmbeddedBenchmarksMatchSourceYAML() throws {
        let cases: [(String, String)] = [
            (BenchmarkProfile.cis.localFilename, EmbeddedBenchmarks.cisMacOS),
            (BenchmarkProfile.personal.localFilename, EmbeddedBenchmarks.personalProtectionMacOS),
        ]

        for (filename, embedded) in cases {
            let url = repositoryRoot
                .appendingPathComponent("Sources/ArmaziCore/Benchmarks")
                .appendingPathComponent(filename)
            try XCTSkipUnless(
                FileManager.default.fileExists(atPath: url.path),
                "Benchmark sources are not available in this test environment"
            )

            let onDisk = try String(contentsOf: url, encoding: .utf8)
            XCTAssertEqual(
                embedded,
                onDisk.trimmingCharacters(in: .newlines),
                "\(filename) is out of sync — run Scripts/embed-benchmarks.py"
            )
        }
    }
}

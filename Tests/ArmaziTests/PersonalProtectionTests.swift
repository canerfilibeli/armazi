import XCTest
@testable import ArmaziCore

/// Tests for the bundled Personal Protection profile.
///
/// These parse the copy embedded in the binary rather than going through
/// `loadBundled(profile:)`, so a local override in ~/.config/armazi cannot
/// change the result.
final class PersonalProtectionTests: XCTestCase {

    private func personalBenchmark() throws -> BenchmarkDefinition {
        try BenchmarkParser.parse(yaml: BenchmarkProfile.personal.embeddedYAML)
    }

    func testEmbeddedProfileParses() throws {
        let benchmark = try personalBenchmark()
        XCTAssertEqual(benchmark.name, "Armazi Personal Protection Benchmark")
        XCTAssertEqual(benchmark.platform, "macOS")
        XCTAssertFalse(benchmark.checks.isEmpty)
    }

    func testCheckIDsAreUnique() throws {
        let ids = try personalBenchmark().checks.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate check IDs in the personal profile")
    }

    func testEveryCheckIsWellFormed() throws {
        for check in try personalBenchmark().checks {
            XCTAssertFalse(check.title.isEmpty, "Missing title for \(check.id)")
            XCTAssertFalse(check.description.isEmpty, "Missing description for \(check.id)")
            XCTAssertFalse(check.audit.command.isEmpty, "Missing audit command for \(check.id)")
            XCTAssertFalse(check.frameworks.isEmpty, "No framework mapping for \(check.id)")
            XCTAssertNotNil(check.remediation, "Missing remediation for \(check.id)")
            XCTAssertTrue((1...2).contains(check.level), "Unexpected level for \(check.id)")
        }
    }

    /// Every personal check signals success with the ARMAZI_PASS token, which
    /// — unlike "PASS" or "OK" — cannot appear inside an ordinary English
    /// failure message such as "no password manager detected".
    func testChecksUseTheUnambiguousPassToken() throws {
        for check in try personalBenchmark().checks {
            guard case .contains(let value) = check.audit.match else {
                XCTFail("\(check.id) should match on ARMAZI_PASS")
                continue
            }
            XCTAssertEqual(value, "ARMAZI_PASS", "\(check.id) matches on an ambiguous token")
            XCTAssertTrue(
                check.audit.command.contains("ARMAZI_PASS"),
                "\(check.id) can never report a pass"
            )
        }
    }

    func testChecksDoNotRequireAdminPrivileges() throws {
        for check in try personalBenchmark().checks {
            XCTAssertFalse(check.elevated, "\(check.id) would force a password prompt")
        }
    }

    func testCoversEveryConsumerCategory() throws {
        let categories = Set(try personalBenchmark().checks.map(\.category))
        XCTAssertEqual(categories, [
            .identityProtection,
            .deviceData,
            .onlineSafety,
            .homeNetwork,
            .privacyFootprint,
            .responseReadiness,
        ])
    }

    func testProfileMetadata() throws {
        XCTAssertEqual(BenchmarkProfile.default, .cis)
        XCTAssertEqual(BenchmarkProfile.personal.fileName, "personal-protection-benchmark.yaml")
        XCTAssertEqual(BenchmarkProfile.cis.fileName, "cis-macos-benchmark.yaml")
        XCTAssertEqual(BenchmarkProfile.allCases.count, 2)
    }

    func testEmbeddedCISProfileStillParses() throws {
        let benchmark = try BenchmarkParser.parse(yaml: BenchmarkProfile.cis.embeddedYAML)
        XCTAssertEqual(benchmark.name, "CIS macOS Benchmark")
    }
}

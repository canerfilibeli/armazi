import XCTest
@testable import ArmaziCore

final class PersonalBenchmarkTests: XCTestCase {

    private func personalBenchmark() throws -> BenchmarkDefinition {
        try BenchmarkParser.parse(yaml: EmbeddedBenchmarks.personalMacOS)
    }

    func testEmbeddedPersonalBenchmarkParses() throws {
        let benchmark = try personalBenchmark()
        XCTAssertEqual(benchmark.name, "Armazi Personal Security Benchmark")
        XCTAssertEqual(benchmark.platform, "macOS")
        XCTAssertFalse(benchmark.checks.isEmpty)
    }

    func testCheckIDsAreUnique() throws {
        let ids = try personalBenchmark().checks.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate check IDs in the personal benchmark")
    }

    func testAllPersonalCategoriesAreCovered() throws {
        let categories = Set(try personalBenchmark().checks.map(\.category))
        XCTAssertTrue(categories.contains(.identityProtection))
        XCTAssertTrue(categories.contains(.dataProtection))
        XCTAssertTrue(categories.contains(.onlineSafety))
        XCTAssertTrue(categories.contains(.networkProtection))
        XCTAssertTrue(categories.contains(.privacy))
    }

    func testChecksHaveRemediationAndFrameworks() throws {
        for check in try personalBenchmark().checks {
            XCTAssertFalse(check.title.isEmpty, "Missing title for \(check.id)")
            XCTAssertFalse(check.description.isEmpty, "Missing description for \(check.id)")
            XCTAssertFalse(check.audit.command.isEmpty, "Missing audit command for \(check.id)")
            XCTAssertFalse(check.frameworks.isEmpty, "No frameworks mapped for \(check.id)")
            XCTAssertFalse(
                check.remediation?.isEmpty ?? true,
                "A failing check needs remediation guidance: \(check.id)"
            )
            XCTAssertTrue((1...2).contains(check.level), "Level must be 1 or 2 for \(check.id)")
        }
    }

    /// Elevated checks are concatenated into a single batch script, so an `exit`
    /// in one command would end the batch and drop every later check.
    func testElevatedChecksDoNotCallExit() throws {
        for check in try personalBenchmark().checks where check.elevated {
            let lines = check.audit.command.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                XCTAssertFalse(
                    trimmed == "exit" || trimmed.hasPrefix("exit "),
                    "Elevated check \(check.id) calls exit, which would abort the batch"
                )
            }
        }
    }

    func testMergeKeepsFirstOccurrenceOfDuplicateIDs() throws {
        let personal = try personalBenchmark()
        let merged = BenchmarkRegistry.merge(
            [personal, personal],
            name: "Merged",
            description: "Duplicate input"
        )
        XCTAssertEqual(merged.name, "Merged")
        XCTAssertEqual(merged.checks.count, personal.checks.count)
    }

    func testProfilesAreDistinct() throws {
        XCTAssertEqual(BenchmarkProfile.default, .cis)
        XCTAssertEqual(BenchmarkProfile(rawValue: "personal"), .personal)
        XCTAssertNil(BenchmarkProfile(rawValue: "nope"))
        for profile in BenchmarkProfile.allCases {
            XCTAssertFalse(profile.displayName.isEmpty)
            XCTAssertFalse(profile.summary.isEmpty)
        }
    }

    func testCISAndPersonalBenchmarksDoNotShareCheckIDs() throws {
        let cis = try BenchmarkParser.parse(yaml: EmbeddedBenchmarks.cisMacOS)
        let personal = try personalBenchmark()
        let overlap = Set(cis.checks.map(\.id)).intersection(personal.checks.map(\.id))
        XCTAssertTrue(overlap.isEmpty, "Profiles share check IDs: \(overlap.sorted())")
    }
}

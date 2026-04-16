import XCTest
@testable import ArmaziCore

final class BenchmarkParserTests: XCTestCase {

    func testParseBundled() throws {
        let benchmark = try BenchmarkParser.loadBundled()
        XCTAssertEqual(benchmark.name, "CIS macOS Benchmark")
        XCTAssertEqual(benchmark.platform, "macOS")
        XCTAssertFalse(benchmark.checks.isEmpty)
    }

    func testAllChecksHaveRequiredFields() throws {
        let benchmark = try BenchmarkParser.loadBundled()
        for check in benchmark.checks {
            XCTAssertFalse(check.id.isEmpty, "Check ID should not be empty")
            XCTAssertFalse(check.title.isEmpty, "Check title should not be empty for \(check.id)")
            XCTAssertFalse(check.audit.command.isEmpty, "Audit command should not be empty for \(check.id)")
            XCTAssertGreaterThanOrEqual(check.level, 1, "Level should be >= 1 for \(check.id)")
        }
    }

    func testCategoriesCoverAllTypes() throws {
        let benchmark = try BenchmarkParser.loadBundled()
        let categories = Set(benchmark.checks.map(\.category))
        XCTAssertTrue(categories.contains(.accessSecurity))
        XCTAssertTrue(categories.contains(.firewallSharing))
        XCTAssertTrue(categories.contains(.updates))
        XCTAssertTrue(categories.contains(.systemIntegrity))
    }

    func testParseYAMLFromString() throws {
        let yaml = """
        name: "Test Benchmark"
        version: "0.1"
        platform: "macOS"
        description: "Test"
        checks:
          - id: "T.1"
            title: "Echo test"
            description: "Should pass"
            category: "access_security"
            level: 1
            scored: true
            audit:
              command: "echo hello"
              match:
                type: "contains"
                value: "hello"
            remediation: "N/A"
            frameworks: ["cis"]
        """
        let benchmark = try BenchmarkParser.parse(yaml: yaml)
        XCTAssertEqual(benchmark.name, "Test Benchmark")
        XCTAssertEqual(benchmark.checks.count, 1)
        XCTAssertEqual(benchmark.checks[0].id, "T.1")
    }
}

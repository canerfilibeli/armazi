import SwiftUI
import ArmaziCore

final class DashboardViewModel: ObservableObject {
    @Published var benchmark: BenchmarkDefinition?
    @Published var report: ScanReport?
    @Published var selectedCategory: CheckCategory?
    @Published var selectedLevel: Int = 1
    @Published var errorMessage: String?

    let runner = CheckRunner()

    var isRunning: Bool { runner.isRunning }
    var progress: Double { runner.progress }
    var currentCheck: String? { runner.currentCheck }

    init() {
        loadBenchmark()
    }

    func loadBenchmark() {
        do {
            benchmark = try BenchmarkParser.loadBundled()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBenchmark(from url: URL) {
        do {
            benchmark = try BenchmarkParser.parse(fileURL: url)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load benchmark: \(error.localizedDescription)"
        }
    }

    @MainActor
    func runScan() async {
        guard let benchmark else { return }
        report = await runner.run(benchmark: benchmark, level: selectedLevel)
    }

    func results(for category: CheckCategory) -> [CheckResult] {
        report?.results(for: category) ?? []
    }

    func checks(for category: CheckCategory) -> [CheckDefinition] {
        benchmark?.checks.filter { $0.category == category && $0.level <= selectedLevel } ?? []
    }

    var passCount: Int { report?.passCount ?? 0 }
    var failCount: Int { report?.failCount ?? 0 }
    var totalChecks: Int { report?.totalChecks ?? 0 }
    var scorePercentage: Double { report?.scorePercentage ?? 0 }
}

import SwiftUI
import ArmaziCore

final class DashboardViewModel: ObservableObject {
    @Published var benchmark: BenchmarkDefinition?
    @Published var report: ScanReport?
    @Published var selectedCategory: CheckCategory?
    @Published var selectedLevel: Int = 1
    @Published var errorMessage: String?
    @Published var statusMessage: String?
    @Published var isUpdatingBenchmarks = false
    @Published var isImporting = false

    let runner = CheckRunner()

    var isRunning: Bool { runner.isRunning }
    var progress: Double { runner.progress }
    var currentCheck: String? { runner.currentCheck }

    init() {
        loadBenchmark()
        Task { await checkBenchmarkUpdates() }
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
            statusMessage = "Loaded: \(url.lastPathComponent)"
        } catch {
            errorMessage = "Failed to load benchmark: \(error.localizedDescription)"
        }
    }

    @MainActor
    func runScan() async {
        guard let benchmark else { return }
        report = await runner.run(benchmark: benchmark, level: selectedLevel)
    }

    @MainActor
    func updateBenchmarks() async {
        isUpdatingBenchmarks = true
        statusMessage = "Checking for benchmark updates..."

        let result = await BenchmarkUpdater.update()
        switch result {
        case .updated(let files):
            statusMessage = "Updated \(files.count) benchmark(s)"
            loadBenchmark()
        case .upToDate:
            statusMessage = "Benchmarks are up to date"
        case .failed(let reason):
            statusMessage = "Update failed: \(reason)"
        }

        isUpdatingBenchmarks = false

        // Clear status after 4 seconds
        try? await Task.sleep(for: .seconds(4))
        if !isUpdatingBenchmarks { statusMessage = nil }
    }

    @MainActor
    func importXCCDF(from url: URL) async {
        isImporting = true
        statusMessage = "Importing \(url.lastPathComponent)..."

        do {
            let yaml = try XCCDFImporter.importFile(at: url)

            // Save to local benchmarks
            let localDir = BenchmarkParser.localDir
            try FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)
            let dest = localDir.appendingPathComponent(
                url.deletingPathExtension().lastPathComponent + ".yaml"
            )
            try yaml.write(to: dest, atomically: true, encoding: .utf8)

            // Load the imported benchmark
            benchmark = try BenchmarkParser.parse(yaml: yaml)
            statusMessage = "Imported \(benchmark?.checks.count ?? 0) checks from \(url.lastPathComponent)"
            report = nil
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }

        isImporting = false
    }

    func importBenchmarkFile(from url: URL) {
        let ext = url.pathExtension.lowercased()
        if ext == "xml" || ext == "xccdf" {
            Task { await importXCCDF(from: url) }
        } else {
            loadBenchmark(from: url)
        }
    }

    /// Silent check on launch
    @MainActor
    private func checkBenchmarkUpdates() async {
        let result = await BenchmarkUpdater.update()
        if case .updated = result {
            loadBenchmark()
            statusMessage = "Benchmarks updated automatically"
            try? await Task.sleep(for: .seconds(3))
            statusMessage = nil
        }
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

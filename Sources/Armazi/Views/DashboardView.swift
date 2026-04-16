import SwiftUI
import ArmaziCore

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Armazi")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                levelPicker
                scanButton
                importButton
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $viewModel.selectedCategory) {
            Section("Overview") {
                scoreCard
            }

            Section("Categories") {
                ForEach(CheckCategory.allCases) { category in
                    categoryRow(category)
                        .tag(category)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var scoreCard: some View {
        VStack(spacing: 12) {
            if viewModel.report != nil {
                ScoreRingView(percentage: viewModel.scorePercentage)
                    .frame(width: 80, height: 80)

                HStack(spacing: 16) {
                    statBadge(count: viewModel.passCount, label: "Pass", color: .green)
                    statBadge(count: viewModel.failCount, label: "Fail", color: .red)
                }
            } else if viewModel.runner.isRunning {
                ProgressView(value: viewModel.progress) {
                    Text(viewModel.currentCheck ?? "Scanning...")
                        .font(.caption)
                        .lineLimit(1)
                }
            } else {
                Text("Run a scan to see results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private func statBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func categoryRow(_ category: CheckCategory) -> some View {
        let results = viewModel.results(for: category)
        let checks = viewModel.checks(for: category)
        let passCount = results.filter { $0.status == .pass }.count
        let total = results.isEmpty ? checks.count : results.count

        return Label {
            HStack {
                Text(category.displayName)
                Spacer()
                if !results.isEmpty {
                    Text("\(passCount)/\(total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: category.icon)
                .foregroundStyle(category.color)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if let category = viewModel.selectedCategory {
            CategoryDetailView(
                category: category,
                checks: viewModel.checks(for: category),
                results: viewModel.results(for: category)
            )
        } else {
            overviewDetail
        }
    }

    private var overviewDetail: some View {
        VStack(spacing: 24) {
            if viewModel.benchmark == nil {
                ContentUnavailableView(
                    "No Benchmark Loaded",
                    systemImage: "doc.questionmark",
                    description: Text("Load a benchmark YAML file or use the bundled CIS macOS Benchmark.")
                )
            } else if viewModel.report == nil && !viewModel.runner.isRunning {
                ContentUnavailableView(
                    "Ready to Scan",
                    systemImage: "shield.checkered",
                    description: Text("Click \"Scan\" to check your system against \(viewModel.benchmark?.name ?? "the benchmark").")
                )
            } else if viewModel.runner.isRunning {
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 300)
                    Text(viewModel.currentCheck ?? "Running checks...")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else if let report = viewModel.report {
                ReportView(report: report)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    private var levelPicker: some View {
        Picker("Level", selection: $viewModel.selectedLevel) {
            Text("Level 1").tag(1)
            Text("Level 2").tag(2)
        }
        .pickerStyle(.segmented)
        .frame(width: 160)
        .help("CIS Benchmark profile level")
    }

    private var scanButton: some View {
        Button {
            Task { await viewModel.runScan() }
        } label: {
            Label("Scan", systemImage: "play.fill")
        }
        .disabled(viewModel.runner.isRunning || viewModel.benchmark == nil)
        .help("Run all checks")
    }

    private var importButton: some View {
        Button {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.yaml]
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            if panel.runModal() == .OK, let url = panel.url {
                viewModel.loadBenchmark(from: url)
            }
        } label: {
            Label("Import", systemImage: "square.and.arrow.down")
        }
        .help("Import a custom benchmark YAML file")
    }
}

import UniformTypeIdentifiers
extension UTType {
    static let yaml = UTType(filenameExtension: "yaml") ?? .plainText
}

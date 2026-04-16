import SwiftUI
import ArmaziCore

struct ReportView: View {
    let report: ScanReport

    private struct CategoryItem: Hashable {
        let category: CheckCategory
        let passCount: Int
        let total: Int
        var percentage: Double { total > 0 ? Double(passCount) / Double(total) * 100 : 0 }
    }

    private struct FrameworkItem: Hashable {
        let framework: ComplianceFramework
        let passCount: Int
        let total: Int
        var percentage: Double { total > 0 ? Double(passCount) / Double(total) * 100 : 0 }
    }

    private var categoriesWithResults: [CategoryItem] {
        CheckCategory.allCases.compactMap { category in
            let results = report.results(for: category)
            guard !results.isEmpty else { return nil }
            let pass = results.filter { $0.status == .pass }.count
            return CategoryItem(category: category, passCount: pass, total: results.count)
        }
    }

    private var frameworksWithResults: [FrameworkItem] {
        ComplianceFramework.allCases.compactMap { fw in
            let results = report.results(for: fw)
            guard !results.isEmpty else { return nil }
            let pass = results.filter { $0.status == .pass }.count
            return FrameworkItem(framework: fw, passCount: pass, total: results.count)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                overviewCard
                categorySummary
                frameworkCompliance
            }
            .padding()
        }
    }

    private var overviewCard: some View {
        HStack(spacing: 32) {
            ScoreRingView(percentage: report.scorePercentage)
                .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 8) {
                Text(report.benchmark.name)
                    .font(.title2.bold())

                Text("v\(report.benchmark.version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                    GridRow {
                        Label("\(report.passCount) passed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Label("\(report.failCount) failed", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    GridRow {
                        Label("\(report.warningCount) warnings", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Label("\(report.errorCount) errors", systemImage: "questionmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
                .font(.callout)

                Text("Completed in \(String(format: "%.1f", report.duration))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var categorySummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.headline)

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(categoriesWithResults, id: \.category) { item in
                    HStack {
                        Image(systemName: item.category.icon)
                            .foregroundStyle(item.category.color)
                        VStack(alignment: .leading) {
                            Text(item.category.displayName)
                                .font(.callout.bold())
                            Text("\(item.passCount)/\(item.total)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ScoreRingView(percentage: item.percentage, lineWidth: 4)
                            .frame(width: 36, height: 36)
                    }
                    .padding(10)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                }
            }
        }
    }

    private var frameworkCompliance: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Framework Compliance")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(frameworksWithResults, id: \.framework) { item in
                    VStack(spacing: 6) {
                        ScoreRingView(percentage: item.percentage, lineWidth: 4)
                            .frame(width: 40, height: 40)
                        Text(item.framework.displayName)
                            .font(.caption.bold())
                        Text("\(item.passCount)/\(item.total)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        }
    }
}

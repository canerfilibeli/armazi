import SwiftUI
import ArmaziCore

struct CategoryDetailView: View {
    let category: CheckCategory
    let checks: [CheckDefinition]
    let results: [CheckResult]

    var body: some View {
        List {
            Section {
                headerView
            }

            Section("Checks") {
                ForEach(checks) { check in
                    let result = results.first { $0.id == check.id }
                    CheckRowView(check: check, result: result)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(category.displayName)
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.largeTitle)
                .foregroundStyle(category.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.title2.bold())

                if !results.isEmpty {
                    let pass = results.filter { $0.status == .pass }.count
                    Text("\(pass) of \(results.count) checks passing")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(checks.count) checks")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !results.isEmpty {
                let pass = results.filter { $0.status == .pass }.count
                let pct = Double(pass) / Double(results.count) * 100
                ScoreRingView(percentage: pct, lineWidth: 6)
                    .frame(width: 50, height: 50)
            }
        }
        .padding(.vertical, 4)
    }
}

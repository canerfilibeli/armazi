import SwiftUI
import ArmaziCore

struct CheckRowView: View {
    let check: CheckDefinition
    let result: CheckResult?
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            detailContent
        } label: {
            labelContent
        }
    }

    private var labelContent: some View {
        HStack(spacing: 10) {
            statusIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(check.title)
                    .font(.body)

                Text(check.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            frameworkBadges
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if let result {
            Image(systemName: result.status.icon)
                .foregroundStyle(result.status.color)
                .font(.title3)
        } else {
            Image(systemName: "circle.dotted")
                .foregroundStyle(.secondary)
                .font(.title3)
        }
    }

    private var frameworkBadges: some View {
        HStack(spacing: 4) {
            ForEach(check.frameworks) { fw in
                Text(fw.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(fw.color.opacity(0.15))
                    .foregroundStyle(fw.color)
                    .clipShape(Capsule())
            }
        }
    }

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let result {
                GroupBox("Result") {
                    Text(result.message)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !result.rawOutput.isEmpty {
                    GroupBox("Raw Output") {
                        ScrollView(.horizontal) {
                            Text(result.rawOutput)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            if let remediation = check.remediation {
                GroupBox("Remediation") {
                    Text(remediation)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack {
                Label("ID: \(check.id)", systemImage: "number")
                Label("Level \(check.level)", systemImage: "slider.horizontal.3")
                Label(check.scored ? "Scored" : "Not Scored", systemImage: check.scored ? "checkmark.seal" : "info.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

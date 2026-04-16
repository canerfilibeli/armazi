import SwiftUI

public enum CheckStatus: String, Codable, Sendable {
    case pass
    case fail
    case warning
    case error
    case skipped

    public var label: String {
        switch self {
        case .pass: "Pass"
        case .fail: "Fail"
        case .warning: "Warning"
        case .error: "Error"
        case .skipped: "Skipped"
        }
    }

    public var icon: String {
        switch self {
        case .pass: "checkmark.circle.fill"
        case .fail: "xmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "questionmark.circle.fill"
        case .skipped: "minus.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .pass: .green
        case .fail: .red
        case .warning: .orange
        case .error: .gray
        case .skipped: .secondary
        }
    }
}

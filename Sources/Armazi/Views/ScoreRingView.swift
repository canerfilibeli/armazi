import SwiftUI

struct ScoreRingView: View {
    let percentage: Double
    var lineWidth: CGFloat = 8

    private var color: Color {
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: percentage)

            Text("\(Int(percentage))%")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

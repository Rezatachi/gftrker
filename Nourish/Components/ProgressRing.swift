import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 16
    var color: Color = NourishColors.lavender

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.14), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(colors: [color, NourishColors.blush, color], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: progress)
    }
}


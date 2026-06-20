import SwiftUI

struct WaterDropletsView: View {
    let ounces: Int
    let goalOunces: Int
    private let segmentCount = 8

    private var filledSegments: Int {
        guard goalOunces > 0 else { return 0 }
        return min(segmentCount, Int((Double(ounces) / Double(goalOunces) * Double(segmentCount)).rounded(.up)))
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<segmentCount, id: \.self) { index in
                Image(systemName: index < filledSegments ? "drop.fill" : "drop")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(index < filledSegments ? NourishColors.blueBell : NourishColors.blueBell.opacity(0.28))
                    .scaleEffect(index == filledSegments - 1 ? 1.08 : 1.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.62), value: filledSegments)
            }
        }
        .accessibilityLabel("\(ounces) of \(goalOunces) ounces")
    }
}

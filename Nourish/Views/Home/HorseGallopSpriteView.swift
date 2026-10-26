import SwiftUI
import UIKit

struct HorseGallopSpriteView: View {
    // get settings from user defaults
    
    private let frameNames = [
        "HorseGallopFrame0",
        "HorseGallopFrame1",
        "HorseGallopFrame2",
        "HorseGallopFrame3",
        "HorseGallopFrame4",
        "HorseGallopFrame5",
        "HorseGallopFrame6",
        "HorseGallopFrame7"
    ]

    private let frameDuration: TimeInterval = 0.11

    var displayWidth: CGFloat = 240
    var displayHeight: CGFloat = 144

    var body: some View {
        TimelineView(.periodic(from: .now, by: frameDuration)) { timeline in
            let index = Int(timeline.date.timeIntervalSinceReferenceDate / frameDuration) % frameNames.count

            frameImage(name: frameNames[index])
                .frame(width: displayWidth, height: displayHeight)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func frameImage(name: String) -> some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .renderingMode(.original)
                .interpolation(.none)
                .antialiased(false)
                .resizable()
                .scaledToFit()
                .foregroundStyle(NourishColors.lavender)
        } else {
            Color.clear
        }
    }
}

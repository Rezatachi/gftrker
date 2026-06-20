import SwiftUI

struct NourishShadow: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: NourishColors.lavender.opacity(0.14), radius: 22, x: 0, y: 14)
    }
}

extension View {
    func nourishShadow() -> some View {
        modifier(NourishShadow())
    }
}


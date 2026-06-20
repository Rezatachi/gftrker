import SwiftUI

enum NourishColors {
    static let charcoalBlue = Color(red: 0.22, green: 0.25, blue: 0.32)
    static let blueBell = Color(red: 0.00, green: 0.55, blue: 0.84)
    static let almondSilk = Color(red: 0.87, green: 0.73, blue: 0.69)
    static let bubblegumPink = Color(red: 0.96, green: 0.39, blue: 0.46)
    static let magentaBloom = Color(red: 0.89, green: 0.25, blue: 0.44)
    static let cream = Color(red: 0.98, green: 0.93, blue: 0.91)
    static let blush = bubblegumPink
    static let blushSoft = Color(red: 0.99, green: 0.83, blue: 0.85)
    static let lavender = blueBell
    static let lavenderDeep = charcoalBlue
    static let mint = Color(red: 0.48, green: 0.71, blue: 0.78)
    static let mintSoft = Color(red: 0.84, green: 0.93, blue: 0.95)
    static let ink = charcoalBlue
    static let muted = Color(red: 0.42, green: 0.43, blue: 0.48)
    static let card = Color.white.opacity(0.82)
    static let line = Color(red: 0.88, green: 0.77, blue: 0.76)

    static let background = LinearGradient(
        colors: [cream, Color(red: 0.96, green: 0.88, blue: 0.90), Color(red: 0.88, green: 0.94, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppTheme {
    let background: LinearGradient
    let accent: Color
    let secondaryAccent: Color
    let softSurface: Color
    let deepAccent: Color
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = ThemeVariant.sageGreen.palette
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

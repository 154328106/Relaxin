import SwiftUI
import UIKit

/// Liquid-glass theme: light sky-blue gradient surface, near-black text, iOS
/// system-blue accent, SF Pro Rounded for chrome, monospaced kept for terminal.
enum Theme {
    // MARK: - Accents

    /// Primary tint (iOS system blue). Matches SF-Symbol tinting used across
    /// icon badges and the primary action button.
    static let accent = SwiftUI.Color(red: 0.04, green: 0.52, blue: 0.98)

    /// Alternate accents used to differentiate icon badges (mirrors the color
    /// scheme in the reference screenshot: blue / purple / green / orange / …).
    enum Accents {
        static let blue = SwiftUI.Color(red: 0.04, green: 0.52, blue: 0.98)
        static let indigo = SwiftUI.Color(red: 0.35, green: 0.34, blue: 0.84)
        static let purple = SwiftUI.Color(red: 0.62, green: 0.34, blue: 0.92)
        static let pink = SwiftUI.Color(red: 0.98, green: 0.35, blue: 0.60)
        static let orange = SwiftUI.Color(red: 1.00, green: 0.55, blue: 0.20)
        static let teal = SwiftUI.Color(red: 0.20, green: 0.74, blue: 0.82)
        static let green = SwiftUI.Color(red: 0.30, green: 0.78, blue: 0.42)
        static let red = SwiftUI.Color(red: 0.98, green: 0.29, blue: 0.30)
    }

    // MARK: - Text

    /// Primary text — white to read on the deep-blue gradient background.
    static let foreground = SwiftUI.Color.white

    /// Secondary text (subtitles, footnotes).
    static let secondaryForeground = SwiftUI.Color.white.opacity(0.7)

    /// Failure-page foreground: sits over a deep red gradient.
    static let failureForeground = SwiftUI.Color.white

    // MARK: - Backgrounds

    /// Deep-red gradient used by the failure screen. Kept saturated on purpose
    /// so the failure page reads as an alarm even after the palette rework.
    static let failureBackground = SwiftUI.Color(red: 0.72, green: 0, blue: 0)

    // MARK: - Layout

    static let pagePadding: CGFloat = 24
    static let cardCornerRadius: CGFloat = 22
    static let iconBadgeSize: CGFloat = 34

    // MARK: - Typography

    static let fontSize: CGFloat = 15
    static let font = Font.system(size: fontSize, weight: .regular, design: .rounded)
    static let uiFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    /// Large-title font used at the top of each page ("Relaxin" / "更多"-style).
    static let pageTitleFont = Font.system(size: 26, weight: .bold, design: .rounded)

    /// Section-title font used inside grouped glass cards.
    static let sectionTitleFont = Font.system(size: 13, weight: .semibold, design: .rounded)
}

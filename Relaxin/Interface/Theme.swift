import SwiftUI
import UIKit

enum Theme {
    // Dopamine-style blue accent
    static let accent = SwiftUI.Color(red: 0.29, green: 0.66, blue: 0.98)
    static let foreground = SwiftUI.Color.white
    static let background = SwiftUI.Color(red: 0.12, green: 0.23, blue: 0.53)
    static let failureBackground = SwiftUI.Color(red: 0.72, green: 0, blue: 0)

    static let pagePadding: CGFloat = 24

    static let fontSize: CGFloat = 14
    static let font = Font.system(size: fontSize, weight: .regular, design: .monospaced)
    static let uiFont = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
}

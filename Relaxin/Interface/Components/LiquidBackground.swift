import SwiftUI

/// Deep-blue gradient wash that sits behind every page. Kept as a pure
/// LinearGradient (no image asset, no blendMode) because those combinations
/// have historically broken rendering on-device.
struct LiquidBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                SwiftUI.Color(red: 0.10, green: 0.20, blue: 0.45),
                SwiftUI.Color(red: 0.06, green: 0.14, blue: 0.34),
                SwiftUI.Color(red: 0.04, green: 0.09, blue: 0.24),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    LiquidBackground()
}

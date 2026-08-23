import SwiftUI

/// Blue gradient wash that sits behind every page. Kept as a pure
/// LinearGradient (no image asset, no blendMode) because those combinations
/// have historically broken rendering on-device. Colors live in
/// `Theme.backgroundGradient` so every screen shares the same ramp.
struct LiquidBackground: View {
    var body: some View {
        LinearGradient(
            colors: Theme.backgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview {
    LiquidBackground()
}

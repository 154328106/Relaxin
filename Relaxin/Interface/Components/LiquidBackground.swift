import SwiftUI

/// The reusable pale-sky-blue gradient wash that sits behind every liquid-glass
/// page. Keeps the same feel in light and dark mode so the glass surfaces above
/// stay readable regardless of appearance.
struct LiquidBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark ? darkStops : lightStops,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // A second, softer wash on the diagonal to break up the flat gradient
            // and echo the "smoky" highlight in the reference screenshot.
            LinearGradient(
                colors: [
                    SwiftUI.Color.white.opacity(colorScheme == .dark ? 0.04 : 0.55),
                    SwiftUI.Color.clear,
                    SwiftUI.Color.white.opacity(colorScheme == .dark ? 0.02 : 0.30),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(colorScheme == .dark ? .screen : .plusLighter)
        }
        .ignoresSafeArea()
    }

    private var lightStops: [SwiftUI.Color] {
        [
            SwiftUI.Color(red: 0.86, green: 0.92, blue: 1.00),
            SwiftUI.Color(red: 0.94, green: 0.97, blue: 1.00),
            SwiftUI.Color(red: 0.82, green: 0.90, blue: 1.00),
        ]
    }

    private var darkStops: [SwiftUI.Color] {
        [
            SwiftUI.Color(red: 0.05, green: 0.08, blue: 0.18),
            SwiftUI.Color(red: 0.07, green: 0.11, blue: 0.24),
            SwiftUI.Color(red: 0.04, green: 0.07, blue: 0.16),
        ]
    }
}

#Preview {
    LiquidBackground()
}

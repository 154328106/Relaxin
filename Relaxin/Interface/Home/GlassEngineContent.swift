import SwiftUI

/// Full-screen liquid-glass wrapper around the terminal for the `.engine`
/// screen. The terminal engine itself is untouched — this view only reskins
/// its container: glass card, matching gradient, no menu bar.
struct GlassEngineContent: View {
    let title: String
    let terminalText: String
    let onColumnCountChange: (Int) -> Void

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 0) {
                PageNavigationBar(title: title)

                TerminalPresenter(
                    content: terminalText,
                    accessibleLinks: [],
                    allowsOpeningLinks: false,
                    onColumnCountChange: onColumnCountChange,
                    onLongPress: nil
                )
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .glassCard()
                .padding(.bottom, 20)
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 8)
        }
    }
}

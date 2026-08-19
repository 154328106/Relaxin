import SwiftUI

/// Top-of-page bar with a large title and (optionally) a leading back button.
/// Replaces the "Back" entry that used to be buried at the bottom of every
/// sub-page menu.
struct PageNavigationBar: View {
    let title: String
    var subtitle: String? = nil
    var backAction: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let backAction {
                Button(action: backAction) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 40, height: 40)
                        .background {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .strokeBorder(SwiftUI.Color.white.opacity(0.45), lineWidth: 0.8)
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.pageTitleFont)
                    .foregroundStyle(Theme.foreground)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.secondaryForeground)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
    }
}

#Preview {
    ZStack {
        LiquidBackground()
        VStack(alignment: .leading, spacing: 0) {
            PageNavigationBar(title: "Advanced Options", subtitle: "iPhone15,3 · iOS 16.6.1", backAction: {})
            Spacer()
        }
        .padding(Theme.pagePadding)
    }
}

import SwiftUI

/// A translucent rounded surface with a subtle white highlight border. Used
/// for menu rows, cards, and the floating dock.
///
/// Composition rules (learned the hard way in DopamineHeroContent):
/// - No `.shadow` — a soft highlight ring is faked with a second stroke.
/// - No GeometryReader — this is a pure layered background suitable to be
///   dropped anywhere as `.modifier(GlassCard())` or `.glassCard()`.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = Theme.cardCornerRadius
    var isEmphasized: Bool = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(SwiftUI.Color.white.opacity(isEmphasized ? 0.22 : 0.14))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isEmphasized
                            ? Theme.accent.opacity(0.9)
                            : SwiftUI.Color.white.opacity(0.30),
                        lineWidth: isEmphasized ? 1.4 : 0.8
                    )
                    // A Shape overlay hit-tests across its bounding box on
                    // iOS 16 and can swallow taps meant for the button
                    // inside — disable hit testing on the decorative border.
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = Theme.cardCornerRadius,
        isEmphasized: Bool = false
    ) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, isEmphasized: isEmphasized))
    }
}

/// A colored circular badge with a white SF Symbol glyph, mimicking the
/// tinted app-icon style used across iOS 17/18 settings sheets.
struct IconBadge: View {
    let systemImage: String
    let tint: SwiftUI.Color
    var size: CGFloat = Theme.iconBadgeSize

    var body: some View {
        ZStack {
            // Base tint
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(tint)

            // Top highlight — gives the "liquid glass / gel" gel-cap look
            // without relying on `.shadow`.
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SwiftUI.Color.white.opacity(0.35),
                            SwiftUI.Color.white.opacity(0.05),
                            SwiftUI.Color.clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blendMode(.plusLighter)

            // Thin bright rim
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .strokeBorder(SwiftUI.Color.white.opacity(0.35), lineWidth: 0.6)

            Image(systemName: systemImage)
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(SwiftUI.Color.white)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        LiquidBackground()
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                IconBadge(systemImage: "gearshape.fill", tint: Theme.Accents.blue)
                IconBadge(systemImage: "shield.fill", tint: Theme.Accents.indigo)
                IconBadge(systemImage: "slider.horizontal.3", tint: Theme.Accents.purple)
                IconBadge(systemImage: "heart.fill", tint: Theme.Accents.pink)
                IconBadge(systemImage: "wifi", tint: Theme.Accents.teal)
            }

            Text("Card body")
                .frame(maxWidth: .infinity)
                .padding()
                .glassCard()
                .padding()
        }
    }
}

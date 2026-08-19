import SwiftUI

/// Home-screen hero: liquid-glass reskin of Dopamine's original UIKit home. A
/// pale sky-blue gradient sits behind an icon-badge menu list and a big glass
/// primary button. Uses only the primitives that render reliably on-device
/// (plain ZStack/VStack, a single Spacer, SF Symbols, Text) — no
/// GeometryReader, no safeAreaInset, no `.shadow`.
///
/// Used for the idle "home" screen in both the pre-jailbreak (`HomeView`) and
/// post-jailbreak (`PostJailbreakHomeView`) flows.
struct DopamineHeroContent: View {
    struct MenuRow: Identifiable {
        let id: String
        let systemImage: String
        let title: String
        var showsChevron = false
        var isEnabled = true
        var tint: SwiftUI.Color = Theme.accent
        let action: () -> Void
    }

    let headerTitle: String
    let headerSubtitle: String
    let headerFootnote: String
    let menuRows: [MenuRow]
    let primaryButtonTitle: String
    let primaryButtonSystemImage: String
    let isPrimaryButtonEnabled: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer()
                if !menuRows.isEmpty {
                    menuCard
                    Spacer().frame(height: 16)
                }
                primaryButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(headerTitle)
                .font(Theme.pageTitleFont)
                .foregroundStyle(Theme.foreground)

            Text(headerSubtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.secondaryForeground)
            Text(headerFootnote)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.secondaryForeground.opacity(0.75))
        }
    }

    private var menuCard: some View {
        VStack(spacing: 12) {
            ForEach(menuRows) { row in
                Button(action: row.action) {
                    HStack(spacing: 14) {
                        IconBadge(systemImage: row.systemImage, tint: row.tint)
                        Text(row.title)
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(Theme.foreground)
                            .lineLimit(1)
                        Spacer()
                        if row.showsChevron {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.secondaryForeground.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!row.isEnabled)
                .opacity(row.isEnabled ? 1 : 0.45)
                .glassCard()
            }
        }
    }

    private var primaryButton: some View {
        Button(action: onPrimaryAction) {
            HStack(spacing: 10) {
                Image(systemName: primaryButtonSystemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(primaryButtonTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(SwiftUI.Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.accent)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SwiftUI.Color.white.opacity(0.28),
                                    SwiftUI.Color.clear,
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.plusLighter)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(SwiftUI.Color.white.opacity(0.4), lineWidth: 0.8)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isPrimaryButtonEnabled)
        .opacity(isPrimaryButtonEnabled ? 1 : 0.55)
    }
}

#Preview {
    DopamineHeroContent(
        headerTitle: "Relaxin",
        headerSubtitle: "iPhone \u{2022} iOS 17.3.1",
        headerFootnote: "RootHide Jailbreak Engine",
        menuRows: [
            .init(id: "advancedOptions", systemImage: "slider.horizontal.3", title: "Advanced Options", showsChevron: true, tint: Theme.Accents.blue) {},
            .init(id: "maintenance", systemImage: "wrench.and.screwdriver.fill", title: "Maintenance Tools", showsChevron: true, tint: Theme.Accents.orange) {},
            .init(id: "credits", systemImage: "heart.fill", title: "Credits", showsChevron: true, tint: Theme.Accents.pink) {},
        ],
        primaryButtonTitle: "Jailbreak",
        primaryButtonSystemImage: "lock.open.fill",
        isPrimaryButtonEnabled: true,
        onPrimaryAction: {}
    )
}

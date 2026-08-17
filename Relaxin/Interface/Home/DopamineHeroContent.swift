import SwiftUI

/// A faithful recreation of Dopamine's real UIKit home screen (DOMainViewController /
/// DOHeaderView / DOActionMenuView / DOJailbreakButton), ported to SwiftUI: a full-bleed
/// photo background, a top-left logo+subtitle header, a translucent rounded action-menu
/// card, and a separate translucent rounded primary button below it. Structure, spacing,
/// and behavior (chevrons only on navigating rows, disabled rows dimmed, disabled primary
/// button at 70% opacity) mirror the upstream layout; colors/typography are approximated
/// since Dopamine's own theme-color source wasn't recoverable.
///
/// Used for the idle "home" screen in both the pre-jailbreak (`HomeView`) and
/// post-jailbreak (`PostJailbreakHomeView`) flows; everything reachable from the original
/// terminal-driven home menu remains reachable here.
///
/// Deliberately built from only the small set of primitives already confirmed (by
/// on-device screenshots) to render correctly in this app: plain ZStack/VStack, a single
/// unconstrained Spacer, SF Symbols, and Text -- no GeometryReader, no safeAreaInset, no
/// custom vector asset in the header, no shadow modifier. Earlier attempts combining
/// those produced broken/blank layouts on-device for reasons that weren't isolated;
/// this version lets the VStack respect the safe area normally instead of fighting it.
struct DopamineHeroContent: View {
    struct MenuRow: Identifiable {
        let id: String
        let systemImage: String
        let title: String
        var showsChevron = false
        var isEnabled = true
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
            Image("HeroBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(SwiftUI.Color.black.opacity(0.18))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header
                Spacer()
                if !menuRows.isEmpty {
                    menuCard
                    Spacer().frame(height: 16)
                }
                primaryButton
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 24)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                Text(headerTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(headerSubtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
            Text(headerFootnote)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var menuCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(menuRows.enumerated()), id: \.element.id) { index, row in
                Button(action: row.action) {
                    HStack(spacing: 10) {
                        Image(systemName: row.systemImage)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 20)
                        Text(row.title)
                            .font(.system(size: 17, weight: .regular))
                            .lineLimit(1)
                        Spacer()
                        if row.showsChevron {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(height: 52)
                    .padding(.horizontal, 20)
                    .contentShape(Rectangle())
                }
                .disabled(!row.isEnabled)
                .opacity(row.isEnabled ? 1 : 0.4)

                if index != menuRows.count - 1 {
                    Rectangle()
                        .fill(SwiftUI.Color.white.opacity(0.15))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SwiftUI.Color.black.opacity(0.4))
        )
    }

    private var primaryButton: some View {
        Button(action: onPrimaryAction) {
            HStack(spacing: 8) {
                Image(systemName: primaryButtonSystemImage)
                    .font(.system(size: 14, weight: .medium))
                Text(primaryButtonTitle)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SwiftUI.Color.black.opacity(0.4))
            )
        }
        .disabled(!isPrimaryButtonEnabled)
        .opacity(isPrimaryButtonEnabled ? 1 : 0.7)
    }
}

#Preview {
    DopamineHeroContent(
        headerTitle: "Relaxin",
        headerSubtitle: "iPhone \u{2022} iOS 17.3.1",
        headerFootnote: "RootHide Jailbreak Engine",
        menuRows: [
            .init(
                id: "advancedOptions",
                systemImage: "gearshape",
                title: "Advanced Options",
                showsChevron: true
            ) {},
            .init(
                id: "maintenance",
                systemImage: "wrench.and.screwdriver",
                title: "Maintenance Tools",
                showsChevron: true
            ) {},
            .init(id: "credits", systemImage: "info.circle", title: "Credits", showsChevron: true) {},
        ],
        primaryButtonTitle: "Jailbreak",
        primaryButtonSystemImage: "lock.open",
        isPrimaryButtonEnabled: true,
        onPrimaryAction: {}
    )
}

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
        ZStack(alignment: .topLeading) {
            Image("HeroBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(SwiftUI.Color.black.opacity(0.18))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                header
                if !menuRows.isEmpty {
                    menuCard
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 24)
        }
        // Docks the button to the bottom of the screen unconditionally, regardless of
        // how much (or how little) content is above it -- avoids relying on Spacer
        // math inside a ZStack, which previously let the button be laid out below the
        // visible viewport.
        .safeAreaInset(edge: .bottom) {
            primaryButton
                .padding(.horizontal, 30)
                .padding(.bottom, 16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image("BootLogoMark")
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .environment(\.colorScheme, .dark)
                Text(headerTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.3), radius: 12)

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

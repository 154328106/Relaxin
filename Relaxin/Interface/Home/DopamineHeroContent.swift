import SwiftUI

/// Home-screen hero (flat variant): a centered oversized Relaxin title, then
/// two labelled sections — 系统信息 (适用设备 / 软件版本 / 当前设备 / 越狱状态
/// 或运行时间) as one grouped glass card whose rows are badge + label +
/// right-aligned value, hairline-separated; and 控制中心, where every menu row
/// is its own glass card so the list breathes. Closed by a gradient primary
/// button.
///
/// Uses only the primitives already confirmed to render on-device — no
/// GeometryReader, no `.shadow`, no `.blendMode` on containers, no
/// `.ultraThinMaterial` on hero cards.
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

    /// Single horizontal info row: badge + label + value on one line.
    struct InfoRow: Identifiable {
        let id: String
        let systemImage: String
        let tint: SwiftUI.Color
        let label: String
        let value: String
        var liveUptime: Bool = false
    }

    let headerTitle: String
    var infoSectionTitle: String = "系统信息"
    var menuSectionTitle: String = "控制中心"
    var infoRows: [InfoRow] = []
    let menuRows: [MenuRow]
    let primaryButtonTitle: String
    let primaryButtonSystemImage: String
    let isPrimaryButtonEnabled: Bool
    let onPrimaryAction: () -> Void

    private static let infoBadgeSize: CGFloat = 28
    private static let menuBadgeSize: CGFloat = 30

    /// Left/right inset used by row content and by the hairline separators,
    /// so the separators run the full width of the card content.
    private static let rowInset: CGFloat = 16

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 0) {
                title
                    .padding(.bottom, 26)

                if !infoRows.isEmpty {
                    sectionHeader(infoSectionTitle)
                    infoCard
                }

                if !menuRows.isEmpty {
                    sectionHeader(menuSectionTitle)
                        .padding(.top, infoRows.isEmpty ? 0 : 26)
                    menuStack
                }

                Spacer(minLength: 12)

                primaryButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    // MARK: - Title

    private var title: some View {
        Text(headerTitle)
            // Deliberately larger than Theme.pageTitleFont: on the home page
            // the title is the only chrome above the cards and carries the
            // whole header.
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }

    // MARK: - Section header

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Theme.sectionTitleFont)
            .foregroundStyle(SwiftUI.Color.white.opacity(0.55))
            .padding(.leading, 6)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 系统信息 card

    private var infoCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(infoRows.enumerated()), id: \.element.id) { index, row in
                infoRowView(row)

                if index != infoRows.count - 1 {
                    // 0.5pt at low opacity washes out completely against the
                    // blue ramp on a 3x screen, so this is a full point.
                    SwiftUI.Color.white.opacity(0.22)
                        .frame(height: 1)
                        .padding(.horizontal, Self.rowInset)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
    }

    @ViewBuilder
    private func infoRowView(_ row: InfoRow) -> some View {
        if row.liveUptime {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                infoRowBody(row: row, value: DeviceInfo.uptimeChinese)
            }
        } else {
            infoRowBody(row: row, value: row.value)
        }
    }

    private func infoRowBody(row: InfoRow, value: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: row.systemImage, tint: row.tint, size: Self.infoBadgeSize)
            Text(row.label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.foreground)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, Self.rowInset)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 控制中心 (one glass card per row)

    private var menuStack: some View {
        VStack(spacing: 11) {
            ForEach(menuRows) { row in
                HStack(spacing: 12) {
                    IconBadge(systemImage: row.systemImage, tint: row.tint, size: Self.menuBadgeSize)
                    Text(row.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.foreground)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if row.showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.secondaryForeground.opacity(0.6))
                    }
                }
                .padding(.horizontal, Self.rowInset)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .opacity(row.isEnabled ? 1 : 0.45)
                // See grouped variant: iOS 16.6.1 was silently dropping
                // Button.action for these rows post-jailbreak — direct tap
                // gesture avoids that.
                .onTapGesture {
                    guard row.isEnabled else { return }
                    row.action()
                }
                .glassCard(cornerRadius: 18)
            }
        }
    }

    // MARK: - Primary button (gradient pill)

    private var primaryButton: some View {
        Button(action: onPrimaryAction) {
            HStack(spacing: 10) {
                Image(systemName: primaryButtonSystemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(primaryButtonTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(SwiftUI.Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SwiftUI.Color(red: 0.32, green: 0.62, blue: 1.00),
                                SwiftUI.Color(red: 0.08, green: 0.42, blue: 0.94),
                                SwiftUI.Color(red: 0.24, green: 0.38, blue: 0.90),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(SwiftUI.Color.white.opacity(0.35), lineWidth: 0.8)
                    // strokeBorder overlays swallow taps on iOS 16.6.1.
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isPrimaryButtonEnabled)
        .opacity(isPrimaryButtonEnabled ? 1 : 0.85)
    }
}

import SwiftUI

/// Home-screen hero (flat variant): centered Relaxin title, a vertical stack
/// of individual horizontal glass info rows (适用设备 / 当前设备 / 运行时间 /
/// 软件版本), individual menu glass rows, and a gradient primary button.
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
    var infoRows: [InfoRow] = []
    let menuRows: [MenuRow]
    let primaryButtonTitle: String
    let primaryButtonSystemImage: String
    let isPrimaryButtonEnabled: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 0) {
                title
                    .padding(.bottom, 14)

                if !infoRows.isEmpty {
                    infoStack
                }

                Spacer(minLength: 12)

                if !menuRows.isEmpty {
                    menuStack
                    Spacer().frame(height: 16)
                }
                primaryButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    // MARK: - Title

    private var title: some View {
        Text(headerTitle)
            .font(Theme.pageTitleFont)
            .foregroundStyle(Theme.foreground)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }

    // MARK: - Info stack

    private var infoStack: some View {
        VStack(spacing: 10) {
            ForEach(infoRows) { row in
                infoCard(row)
            }
        }
    }

    @ViewBuilder
    private func infoCard(_ row: InfoRow) -> some View {
        if row.liveUptime {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                infoCardRow(row: row, value: DeviceInfo.uptimeChinese)
            }
        } else {
            infoCardRow(row: row, value: row.value)
        }
    }

    private func infoCardRow(row: InfoRow, value: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: row.systemImage, tint: row.tint, size: 28)
            Text(row.label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.secondaryForeground)
                .fixedSize(horizontal: true, vertical: false)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 18)
    }

    // MARK: - Menu stack (individual glass rows)

    private var menuStack: some View {
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
            }
        }
        .buttonStyle(.plain)
        .disabled(!isPrimaryButtonEnabled)
        .opacity(isPrimaryButtonEnabled ? 1 : 0.55)
    }
}

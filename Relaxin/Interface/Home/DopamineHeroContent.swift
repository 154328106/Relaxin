import SwiftUI

/// Home-screen hero: big Relaxin title, a stack of glass info cards
/// (适用设备 / 当前设备 / 运行时间 / 软件版本), the icon-badge menu list, and
/// a glass primary action button — all on the deep-blue LiquidBackground.
///
/// Uses only the primitives already confirmed to render on-device: plain
/// ZStack/VStack, SF Symbols, Text, LinearGradient. No GeometryReader, no
/// safeAreaInset, no `.shadow`, no `.blendMode` on the containers.
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

    /// A label/value pair rendered inside a small glass info card at the top
    /// of the hero. Pass `liveUptime: true` and the card refreshes its value
    /// every second by re-reading `DeviceInfo.uptimeChinese`.
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
                header
                Spacer(minLength: 12)
                if !menuRows.isEmpty {
                    menuCard
                    Spacer().frame(height: 16)
                }
                primaryButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(headerTitle)
                .font(Theme.pageTitleFont)
                .foregroundStyle(Theme.foreground)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 10) {
                ForEach(infoRows) { row in
                    infoCard(row)
                }
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

    // MARK: - Menu

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

    // MARK: - Primary button

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
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.accent)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(SwiftUI.Color.white.opacity(0.35), lineWidth: 0.8)
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
        infoRows: [
            .init(id: "supported", label: "适用设备：", value: "iOS 16.5.1-17.3.1"),
            .init(id: "current", label: "当前设备：", value: "iPhone15,3 iOS 16.6.1"),
            .init(id: "uptime", label: "运行时间：", value: "0天 12时 50分 05秒", liveUptime: true),
            .init(id: "version", label: "软件版本：", value: "0.4.6 · RootHide Jailbreak"),
        ],
        menuRows: [
            .init(id: "advancedOptions", systemImage: "slider.horizontal.3", title: "高级选项", showsChevron: true, tint: Theme.Accents.blue) {},
            .init(id: "maintenance", systemImage: "wrench.and.screwdriver.fill", title: "维护工具", showsChevron: true, tint: Theme.Accents.orange) {},
            .init(id: "credits", systemImage: "heart.fill", title: "特别鸣谢", showsChevron: true, tint: Theme.Accents.pink) {},
        ],
        primaryButtonTitle: "开始越狱",
        primaryButtonSystemImage: "lock.open.fill",
        isPrimaryButtonEnabled: true,
        onPrimaryAction: {}
    )
}

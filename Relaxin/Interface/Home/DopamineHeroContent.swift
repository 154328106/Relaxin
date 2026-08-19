import SwiftUI

/// Home-screen hero: centered Relaxin title, a "System Overview" glass card
/// (2×2 info grid), a "Tools & Settings" glass card (menu list with dividers),
/// and a gradient primary button. Uses only the primitives already confirmed
/// to render on-device — no GeometryReader, no `.shadow`, no `.blendMode`
/// on containers, no `.ultraThinMaterial` on hero cards.
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

    /// One cell inside the System Overview 2×2 info grid.
    struct InfoItem: Identifiable {
        let id: String
        let systemImage: String
        let tint: SwiftUI.Color
        let label: String
        let value: String
        var liveUptime: Bool = false
    }

    let headerTitle: String
    var systemOverviewTitle: String = "系统概览"
    var toolsSectionTitle: String = "设置与工具"
    var infoItems: [InfoItem] = []
    let menuRows: [MenuRow]
    let primaryButtonTitle: String
    let primaryButtonSystemImage: String
    let isPrimaryButtonEnabled: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 20) {
                title

                if !infoItems.isEmpty {
                    systemOverviewCard
                }

                Spacer(minLength: 0)

                if !menuRows.isEmpty {
                    toolsCard
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

    // MARK: - System Overview card

    private var systemOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(systemOverviewTitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.foreground)

            SwiftUI.Color.white.opacity(0.14)
                .frame(height: 0.5)

            infoGrid
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
    }

    private var infoGrid: some View {
        // Two-column grid — pairs items 0/1 in the first row, 2/3 in the
        // second. We avoid LazyVGrid here to keep the layout stack simple.
        VStack(spacing: 16) {
            ForEach(0 ..< pairedRows.count, id: \.self) { rowIndex in
                let pair = pairedRows[rowIndex]
                HStack(alignment: .top, spacing: 12) {
                    infoCell(pair.0)
                    if let second = pair.1 {
                        infoCell(second)
                    } else {
                        SwiftUI.Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var pairedRows: [(InfoItem, InfoItem?)] {
        var out: [(InfoItem, InfoItem?)] = []
        var index = 0
        while index < infoItems.count {
            let first = infoItems[index]
            let second = (index + 1 < infoItems.count) ? infoItems[index + 1] : nil
            out.append((first, second))
            index += 2
        }
        return out
    }

    @ViewBuilder
    private func infoCell(_ item: InfoItem) -> some View {
        if item.liveUptime {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                infoCellBody(item: item, value: DeviceInfo.uptimeChinese)
            }
        } else {
            infoCellBody(item: item, value: item.value)
        }
    }

    private func infoCellBody(item: InfoItem, value: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            IconBadge(systemImage: item.systemImage, tint: item.tint, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.secondaryForeground)
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tools & Settings card

    private var toolsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(toolsSectionTitle)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.foreground)
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 8)

            SwiftUI.Color.white.opacity(0.14)
                .frame(height: 0.5)
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                ForEach(Array(menuRows.enumerated()), id: \.element.id) { index, row in
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
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .opacity(row.isEnabled ? 1 : 0.45)
                    // Bug: SwiftUI Button.action closures were silently
                    // dropped for the post-jailbreak home rows on iOS 16.6.1.
                    // .onTapGesture is dispatched directly by the gesture
                    // recognizer and doesn't hit that path.
                    .onTapGesture {
                        guard row.isEnabled else { return }
                        row.action()
                    }

                    if index != menuRows.count - 1 {
                        SwiftUI.Color.white.opacity(0.10)
                            .frame(height: 0.5)
                            .padding(.leading, 18 + 34 + 14)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22)
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

#Preview {
    DopamineHeroContent(
        headerTitle: "Relaxin",
        infoItems: [
            .init(id: "current", systemImage: "iphone", tint: Theme.Accents.blue, label: "当前设备", value: "iPhone15,3 iOS 16.6.1"),
            .init(id: "uptime", systemImage: "stopwatch.fill", tint: Theme.Accents.teal, label: "运行时间", value: "0天 09:00:13", liveUptime: true),
            .init(id: "supported", systemImage: "checkmark.seal.fill", tint: Theme.Accents.green, label: "兼容版本", value: "iOS 16.5.1-17.3.1"),
            .init(id: "version", systemImage: "shippingbox.fill", tint: Theme.Accents.orange, label: "软件版本", value: "0.4.6 · RootHide Jailbreak"),
        ],
        menuRows: [
            .init(id: "advancedOptions", systemImage: "slider.horizontal.3", title: "高级选项", showsChevron: true, tint: Theme.Accents.blue) {},
            .init(id: "maintenance", systemImage: "wrench.and.screwdriver.fill", title: "维护工具", showsChevron: true, tint: Theme.Accents.orange) {},
            .init(id: "credits", systemImage: "heart.fill", title: "特别鸣谢", showsChevron: true, tint: Theme.Accents.pink) {},
        ],
        primaryButtonTitle: "开始越狱",
        primaryButtonSystemImage: "lock.fill",
        isPrimaryButtonEnabled: true,
        onPrimaryAction: {}
    )
}

import SwiftUI

/// Home-screen hero: a glass card whose header is the centered Relaxin
/// title over a 2×2 info grid, a "Tools & Settings" glass card (menu list),
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

    let headerTitle: String
    var subtitle: String = ""
    // 越狱后在副标题下面再显示一行实时运行时间
    var showsUptime: Bool = false
    var toolsSectionTitle: String = "设置与工具"
    let menuRows: [MenuRow]
    let primaryButtonTitle: String
    let primaryButtonSystemImage: String
    let isPrimaryButtonEnabled: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        // 背景由宿主视图常驻提供 —— 页面自带背景会在转场淡出时把背景一起带走，
        // 中途透出系统白底。
        ZStack {
            VStack(spacing: 0) {
                // 顶部留白：把整个三段往下挪，顶部框不再贴顶（对齐 Dopamine RH）
                Spacer(minLength: 44)

                heroHeaderCard

                Spacer(minLength: 26)

                if !menuRows.isEmpty {
                    toolsCard
                }

                Spacer(minLength: 26)

                // 底部按钮外框：留白和上面两个框完全一致（左右 34、上下 28）
                primaryButton
                    .padding(.horizontal, 34)
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 26)

                Spacer(minLength: 6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        // 背景不在这层了，显式撑满，否则 ZStack 会缩到内容大小、连带转场的几何一起跑偏。
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header (大框套小框：外框内套一个更亮的小框，装标题+副标题)

    private var heroHeaderCard: some View {
        VStack(spacing: 6) {
            Text(headerTitle)
                .font(Theme.pageTitleFont)
                .foregroundStyle(Theme.foreground)
                .frame(maxWidth: .infinity, alignment: .center)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.secondaryForeground)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            if showsUptime {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text("已运行：\(DeviceInfo.uptimeChinese)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.secondaryForeground)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 2)
            }
        }
        // 内框
        .padding(.horizontal, 18)
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 20)
        // 内缩再加大：左右 34(内框更窄/更短)、上下 28(外框上边到内框上边留白更大，去挤)
        .padding(.horizontal, 34)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
    }

    // MARK: - 菜单卡（一比一 Dopamine RH）：外框里每项一个独立小框，
    // 图标+文字整体居中，线框单色图标，禁用项灰掉点不了、不显示 chevron。

    private var toolsCard: some View {
        VStack(spacing: 12) {
            ForEach(menuRows) { row in
                menuButton(row)
            }
        }
        // 统一留白：左右 34(菜单小框宽 == 顶部内框宽)、上下 28(外框上边到
        // 第一个小框上边的间距 == 顶部框那样)
        .padding(.horizontal, 34)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
    }

    private func menuButton(_ row: MenuRow) -> some View {
        HStack(spacing: 8) {
            Image(systemName: row.systemImage)
                .font(.system(size: 18, weight: .regular))
            Text(row.title)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(Theme.foreground)
        // 图标+文字整体居中；chevron 用 overlay 贴右边，不打乱居中
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if row.showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondaryForeground.opacity(0.7))
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        // 每项一个独立小框（加高）
        .glassCard(cornerRadius: 15)
        // 禁用项灰掉（未越狱时的重启项就是这个效果）
        .opacity(row.isEnabled ? 1 : 0.4)
        .contentShape(Rectangle())
        // Button.action 在 iOS 16.6.1 会被静默吞掉，用 onTapGesture 直接派发
        .onTapGesture {
            guard row.isEnabled else { return }
            row.action()
        }
    }

    // MARK: - Primary button (gradient rounded rect)

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
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                // 比上一版降一档，不再那么艳/刺，是柔和的中天蓝
                                SwiftUI.Color(red: 0.30, green: 0.58, blue: 0.94),
                                SwiftUI.Color(red: 0.18, green: 0.48, blue: 0.90),
                                SwiftUI.Color(red: 0.24, green: 0.46, blue: 0.87),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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

#Preview {
    DopamineHeroContent(
        headerTitle: "Relaxin",
        subtitle: "16.5-18.7.1/26.0-26.0.1",
        menuRows: [
            .init(id: "advancedOptions", systemImage: "slider.horizontal.3", title: "高级选项", showsChevron: true, tint: Theme.Accents.blue) {},
            .init(id: "maintenance", systemImage: "wrench.and.screwdriver.fill", title: "维护工具", showsChevron: true, tint: Theme.Accents.orange) {},
            .init(id: "credits", systemImage: "doc.text.fill", title: "更新日志", showsChevron: true, tint: Theme.Accents.teal) {},
        ],
        primaryButtonTitle: "开始越狱",
        primaryButtonSystemImage: "lock.fill",
        isPrimaryButtonEnabled: true,
        onPrimaryAction: {}
    )
}

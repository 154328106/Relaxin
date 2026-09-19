import SwiftUI

/// Liquid-glass sub-page layout: a top nav bar with title + back button, then
/// each menu entry rendered as an icon-badged glass row. Replaces the
/// old terminal + plain-text OptionList that used to render sub-pages.
///
/// Following the DopamineHeroContent lesson: no GeometryReader, no
/// `.safeAreaInset`, no `.shadow` on hero primitives — only proven layered
/// backgrounds.
struct GlassSubPageContent<ActionID: Hashable>: View {
    let title: String
    var subtitle: String? = nil
    let backAction: (() -> Void)?
    let rows: [Row]
    var selectedID: ActionID? = nil
    /// Rows whose id appears here open a Share sheet (UIActivityViewController)
    /// with the paired URL instead of relying on the caller to present it.
    var shareItems: [ActionID: URL] = [:]

    /// Read-only paragraphs shown above the action rows (for example the
    /// release notes page). An empty array keeps the original layout.
    var bodyLines: [String] = []

    struct Row: Identifiable {
        let id: ActionID
        let icon: HomeView.MenuIcon
        let title: String
        var isLoading: Bool = false
        var isDisabled: Bool = false
        let action: () -> Void
    }

    @State private var sharePresentation: GlassSharePresentation?

    var body: some View {
        // 背景由宿主视图常驻提供 —— 页面自带背景会在转场淡出时把背景一起带走，
        // 中途透出系统白底。
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                PageNavigationBar(title: title, subtitle: subtitle, backAction: backAction)

                ScrollView {
                    VStack(spacing: 22) {
                        if !bodyLines.isEmpty {
                            bodyCard
                        }
                        if !rows.isEmpty {
                            rowsCard
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 8)
        }
        // 背景不在这层了，显式撑满，否则 ZStack 会缩到内容大小、连带转场的几何一起跑偏。
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $sharePresentation) { presentation in
            GlassShareSheet(url: presentation.url)
        }
        // Edge-swipe back gesture — belt-and-braces alongside the nav bar's
        // dedicated button, so the user can always get home.
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    guard let backAction else { return }
                    if value.translation.width > 80,
                       abs(value.translation.height) < 60 {
                        backAction()
                    }
                }
        )
    }

    // 更新日志等只读内容：做成和首页一样的大框套小框
    private var bodyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(bodyLines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(
                        .system(
                            size: index == 0 ? 17 : 14,
                            weight: index == 0 ? .bold : .regular,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(index == 0 ? Theme.foreground : Theme.secondaryForeground)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        // 内框
        .glassCard(cornerRadius: 18)
        // 外框（大框套小框）
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
    }

    // 设置行等菜单：整组套进一个大外框，每行仍是独立小框 → 大框套小框
    private var rowsCard: some View {
        VStack(spacing: 12) {
            ForEach(rows) { row in
                rowView(row, isSelected: row.id == selectedID)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
    }

    @ViewBuilder
    private func rowView(_ row: Row, isSelected: Bool) -> some View {
        Button(action: {
            // If the tapped row has a share URL, open the sheet first — the
            // caller's action still fires (typically it's the state update
            // that produced the URL in the first place).
            if let url = shareItems[row.id] {
                sharePresentation = GlassSharePresentation(url: url)
            } else {
                row.action()
            }
        }) {
            HStack(spacing: 14) {
                IconBadge(systemImage: row.icon.systemImage, tint: row.icon.tint)
                Text(row.title)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(Theme.foreground)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if row.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.accent)
                } else if let chevron = row.icon.chevron {
                    Image(systemName: chevron)
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
        .disabled(row.isDisabled || row.isLoading)
        .opacity(row.isDisabled ? 0.45 : 1)
        // 小框圆角跟首页菜单小框一致(15)，别用默认 22 那种又圆又长的胶囊
        .glassCard(cornerRadius: 15, isEmphasized: isSelected)
    }
}

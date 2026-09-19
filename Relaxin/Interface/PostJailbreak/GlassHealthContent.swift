import RelaxinPostJailbreak
import SwiftUI

/// Health page: one glass card per check, in the same 大框套小框 layout as the
/// hero menu. Repairable items get an inline repair button.
///
/// Same composition rules as DopamineHeroContent — no GeometryReader, no
/// `.shadow`, and taps go through `onTapGesture` because `Button`'s action is
/// silently swallowed inside these cards on iOS 16.6.1.
struct GlassHealthContent: View {
    let subtitle: String?
    let backAction: (() -> Void)?
    let items: [HealthSession.Item]
    let isScanning: Bool
    let lastScanAt: Date?
    let repairingID: String?
    let onRescan: () -> Void
    let onRepair: (String) -> Void

    private var isBusy: Bool {
        isScanning || repairingID != nil
    }

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 0) {
                PageNavigationBar(
                    title: "健康状态检测",
                    subtitle: subtitle,
                    backAction: backAction
                )

                ScrollView {
                    VStack(spacing: 22) {
                        itemsCard
                        rescanCard
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
        // 扫描太快，肉眼看不出变化 —— 用震动+时间戳给出明确反馈。
        .modifier(LightImpactFeedbackModifier(trigger: lastScanAt))
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

    private var itemsCard: some View {
        VStack(spacing: 12) {
            if items.isEmpty {
                Text(isScanning ? "正在检测…" : "暂无检测结果")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.secondaryForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(items) { item in
                    itemRow(item)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
    }

    private func itemRow(_ item: HealthSession.Item) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                IconBadge(
                    systemImage: Self.symbol(for: item.id),
                    tint: item.state.tint
                )
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.foreground)
                    .lineLimit(1)
                Spacer(minLength: 8)
                statusBadge(item.state)
            }

            Text(item.detail)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.secondaryForeground)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.canRepair {
                repairButton(for: item)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 15)
    }

    private func statusBadge(_ state: RLXHealthState) -> some View {
        Text(state.badgeTitle)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(state.tint.opacity(0.32))
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(state.tint.opacity(0.75), lineWidth: 0.9)
                    .allowsHitTesting(false)
            }
    }

    private func repairButton(for item: HealthSession.Item) -> some View {
        let isRepairing = repairingID == item.id
        return HStack(spacing: 6) {
            if isRepairing {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(isRepairing ? "修复中…" : "修复")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Theme.foreground)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 12)
        .opacity(isBusy && !isRepairing ? 0.4 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isBusy else { return }
            onRepair(item.id)
        }
    }

    private var rescanCard: some View {
        VStack(spacing: 10) {
            rescanButton
            // A scan finishes in well under a frame, so without this the
            // tap looks like it did nothing at all.
            Text(lastScanAt.map { "上次检测 " + $0.formatted(date: .omitted, time: .standard) } ?? "尚未检测")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.secondaryForeground)
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 26)
    }

    private var rescanButton: some View {
        HStack(spacing: 8) {
            if isScanning {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .regular))
            }
            Text(isScanning ? "检测中…" : "重新检测")
                .font(.system(size: 17, weight: .regular, design: .rounded))
        }
        .foregroundStyle(Theme.foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .glassCard(cornerRadius: 15)
        .opacity(isBusy ? 0.4 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isBusy else { return }
            onRescan()
        }
    }

    /// iOS 16.5 is the floor, so every symbol here predates iOS 17 — a newer
    /// one renders as a silent question mark on the supported devices.
    private static func symbol(for identifier: String) -> String {
        switch identifier {
        case RLXHealthIdentifierBootstrap: "internaldrive.fill"
        case RLXHealthIdentifierJailbreakApps: "square.grid.2x2.fill"
        case RLXHealthIdentifierSileo: "shippingbox.fill"
        case RLXHealthIdentifierInjection: "arrow.down.app.fill"
        default: "checkmark.seal.fill"
        }
    }
}

private extension RLXHealthState {
    var tint: SwiftUI.Color {
        switch self {
        case .healthy: Theme.Accents.green
        case .warning: Theme.Accents.orange
        // Repairable reads as actionable rather than alarming — it is the one
        // state that offers a button.
        case .repairable: Theme.Accents.blue
        case .conflict: Theme.Accents.red
        case .disabled: Theme.secondaryForeground
        case .unknown: Theme.secondaryForeground
        @unknown default: Theme.secondaryForeground
        }
    }
}

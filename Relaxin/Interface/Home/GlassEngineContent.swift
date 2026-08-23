import SwiftUI

/// Full-screen liquid-glass wrapper around the terminal for the `.engine`
/// screen. The terminal engine itself is untouched — this view only reskins
/// its container: a live status card (blinking state dot, current step,
/// progress bar) sitting above a console surface with window chrome.
///
/// Same composition rules as the rest of the interface: no GeometryReader,
/// no `.shadow`, no `.blendMode` on containers, no `.ultraThinMaterial` on
/// cards — progress uses the system linear `ProgressView`, and the blinking
/// dot is driven by `TimelineView` (already proven on-device by the uptime
/// cell) instead of a repeating animation.
struct GlassEngineContent: View {
    let title: String
    let terminalText: String
    /// Phase headline — "正在越狱" / "越狱完成" / "越狱失败".
    var statusTitle: String = "正在越狱"
    /// Label of the step currently running, shown monospaced under the headline.
    var statusDetail: String?
    /// 0...1, `nil` while the engine hasn't reported a position/count pair yet.
    var progress: Double?
    /// "03/12" style counter for the same pair.
    var stepText: String?
    var isFinished: Bool = false
    var isFailed: Bool = false
    let onColumnCountChange: (Int) -> Void

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 14) {
                PageNavigationBar(title: title)

                statusCard

                consoleCard
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 8)
        }
    }

    // MARK: - Status card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                statusDot

                VStack(alignment: .leading, spacing: 3) {
                    Text(statusTitle)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.foreground)

                    if let statusDetail, !statusDetail.isEmpty {
                        Text(statusDetail)
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(Theme.secondaryForeground)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer(minLength: 8)

                if let stepText {
                    Text(stepText)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.foreground)
                        .monospacedDigit()
                }
            }

            if let progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(statusTint)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
    }

    /// Blinks while the engine runs; holds steady once it has settled.
    private var statusDot: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { context in
            let isLit = isSettled
                || Int(context.date.timeIntervalSinceReferenceDate / 0.6).isMultiple(of: 2)
            ZStack {
                Circle()
                    .fill(statusTint.opacity(0.28))
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(statusTint)
                    .frame(width: 9, height: 9)
                    .opacity(isLit ? 1 : 0.25)
            }
        }
        .frame(width: 20, height: 20)
    }

    private var isSettled: Bool {
        isFinished || isFailed
    }

    private var statusTint: SwiftUI.Color {
        if isFailed { return Theme.Accents.red }
        if isFinished { return Theme.Accents.green }
        return Theme.Accents.blue
    }

    // MARK: - Console card

    private var consoleCard: some View {
        VStack(spacing: 0) {
            consoleChrome

            SwiftUI.Color.white.opacity(0.10)
                .frame(height: 0.5)

            TerminalPresenter(
                content: terminalText,
                accessibleLinks: [],
                allowsOpeningLinks: false,
                onColumnCountChange: onColumnCountChange,
                onLongPress: nil
            )
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.consoleSurface.opacity(0.72))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            statusTint.opacity(0.55),
                            SwiftUI.Color.white.opacity(0.10),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                // Decorative border — a Shape overlay hit-tests across its
                // whole bounding box on iOS 16 and would eat terminal taps.
                .allowsHitTesting(false)
        }
    }

    /// macOS-style window chrome: three lights, a monospaced session label,
    /// and the percentage on the right.
    private var consoleChrome: some View {
        HStack(spacing: 7) {
            chromeLight(SwiftUI.Color(red: 1.00, green: 0.37, blue: 0.34))
            chromeLight(SwiftUI.Color(red: 1.00, green: 0.74, blue: 0.18))
            chromeLight(SwiftUI.Color(red: 0.16, green: 0.80, blue: 0.35))

            Text("relaxin@\(DeviceInfo.modelIdentifier)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.secondaryForeground.opacity(0.75))
                .lineLimit(1)
                .padding(.leading, 4)

            Spacer(minLength: 8)

            if let progress {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(statusTint)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func chromeLight(_ color: SwiftUI.Color) -> some View {
        Circle()
            .fill(color.opacity(isSettled ? 0.85 : 0.7))
            .frame(width: 9, height: 9)
    }
}

#Preview {
    GlassEngineContent(
        title: "Relaxin",
        terminalText: "",
        statusDetail: "exploiting kernel",
        progress: 0.42,
        stepText: "05/12",
        onColumnCountChange: { _ in }
    )
}

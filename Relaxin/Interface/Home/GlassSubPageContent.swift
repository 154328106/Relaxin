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

    struct Row: Identifiable {
        let id: ActionID
        let icon: HomeView.MenuIcon
        let title: String
        var isLoading: Bool = false
        var isDisabled: Bool = false
        let action: () -> Void
    }

    var body: some View {
        ZStack {
            LiquidBackground()

            VStack(alignment: .leading, spacing: 0) {
                PageNavigationBar(title: title, subtitle: subtitle, backAction: backAction)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(rows) { row in
                            rowView(row)
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

    @ViewBuilder
    private func rowView(_ row: Row) -> some View {
        Button(action: row.action) {
            HStack(spacing: 14) {
                IconBadge(systemImage: row.icon.systemImage, tint: row.icon.tint)
                Text(row.title)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.foreground)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if row.isLoading {
                    ProgressView()
                        .controlSize(.small)
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
        .glassCard()
    }
}

import SwiftUI

/// Optional pill-shaped dock at the bottom of a page (power / infinity / more
/// in the reference screenshot). Placement is up to the caller — this view
/// draws the pill and lets the caller pin it wherever it fits best.
struct FloatingDock: View {
    struct Item: Identifiable {
        let id: String
        let systemImage: String
        var tint: SwiftUI.Color = Theme.accent
        var isHighlighted: Bool = false
        let action: () -> Void
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 24) {
            ForEach(items) { item in
                Button(action: item.action) {
                    ZStack {
                        if item.isHighlighted {
                            Circle()
                                .fill(item.tint.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Circle()
                                .strokeBorder(item.tint.opacity(0.55), lineWidth: 1)
                                .frame(width: 36, height: 36)
                        }
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(item.isHighlighted ? item.tint : Theme.secondaryForeground)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 32, strokeOpacity: 0.65)
    }
}

#Preview {
    ZStack {
        LiquidBackground()
        VStack {
            Spacer()
            FloatingDock(items: [
                .init(id: "power", systemImage: "power", action: {}),
                .init(id: "infinity", systemImage: "infinity", action: {}),
                .init(id: "more", systemImage: "ellipsis", isHighlighted: true, action: {}),
            ])
            .padding(.bottom, 32)
        }
    }
}

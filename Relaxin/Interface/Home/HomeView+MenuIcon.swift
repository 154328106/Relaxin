import SwiftUI

extension HomeView {
    /// Static (SF Symbol name, tint) mapping used to render each MenuAction as
    /// a colored icon badge in the glass sub-page menu.
    struct MenuIcon {
        let systemImage: String
        let tint: SwiftUI.Color
        var chevron: String? = "chevron.right"
    }

    static func icon(for action: MenuAction) -> MenuIcon {
        switch action {
        case .jailbreak:
            return .init(systemImage: "lock.open.fill", tint: Theme.Accents.blue)
        case .advancedOptions:
            return .init(systemImage: "slider.horizontal.3", tint: Theme.Accents.blue)
        case .maintenance:
            return .init(systemImage: "wrench.and.screwdriver.fill", tint: Theme.Accents.orange)
        case .credits:
            return .init(systemImage: "heart.fill", tint: Theme.Accents.pink)
        case .openOwnGoalStudioPicks:
            return .init(systemImage: "star.fill", tint: Theme.Accents.orange)
        case .showSoftwareLicense:
            return .init(systemImage: "doc.text.fill", tint: Theme.Accents.indigo)
        case .toggleOption(let option):
            switch option {
            case .tweakInjection:
                return .init(systemImage: "shippingbox.fill", tint: Theme.Accents.purple, chevron: nil)
            case .appJIT:
                return .init(systemImage: "bolt.fill", tint: Theme.Accents.orange, chevron: nil)
            case .removeJailbreak:
                return .init(systemImage: "trash.fill", tint: Theme.Accents.red, chevron: nil)
            }
        case .jetsamMultiplier:
            return .init(systemImage: "gauge.with.dots.needle.67percent", tint: Theme.Accents.teal)
        case .setJetsamMultiplier:
            return .init(systemImage: "circle.inset.filled", tint: Theme.Accents.blue, chevron: nil)
        case .resetRelaxin:
            return .init(systemImage: "arrow.counterclockwise.circle.fill", tint: Theme.Accents.red)
        case .exportKernelcache:
            return .init(systemImage: "square.and.arrow.up.on.square.fill", tint: Theme.Accents.indigo, chevron: nil)
        case .exportLogs:
            return .init(systemImage: "square.and.arrow.up.fill", tint: Theme.Accents.purple, chevron: nil)
        case .removeJailbreak:
            return .init(systemImage: "trash.fill", tint: Theme.Accents.red, chevron: nil)
        case .confirm:
            return .init(systemImage: "exclamationmark.triangle.fill", tint: Theme.Accents.red, chevron: nil)
        case .back:
            return .init(systemImage: "chevron.backward", tint: Theme.Accents.blue, chevron: nil)
        }
    }
}

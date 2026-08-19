import SwiftUI

extension PostJailbreakHomeView {
    static func icon(for action: MenuAction) -> HomeView.MenuIcon {
        switch action {
        case .advancedOptions:
            return .init(systemImage: "slider.horizontal.3", tint: Theme.Accents.blue)
        case .resetAndRemoval:
            return .init(systemImage: "arrow.counterclockwise.circle.fill", tint: Theme.Accents.orange)
        case .credits:
            return .init(systemImage: "heart.fill", tint: Theme.Accents.pink)
        case .openOwnGoalStudioPicks:
            return .init(systemImage: "star.fill", tint: Theme.Accents.orange)
        case .showSoftwareLicense:
            return .init(systemImage: "doc.text.fill", tint: Theme.Accents.indigo)
        case let .toggleOption(option):
            switch option {
            case .tweakInjection:
                return .init(systemImage: "shippingbox.fill", tint: Theme.Accents.purple, chevron: nil)
            case .appJIT:
                return .init(systemImage: "bolt.fill", tint: Theme.Accents.orange, chevron: nil)
            }
        case .restartSpringBoard:
            return .init(systemImage: "arrow.clockwise", tint: Theme.Accents.teal, chevron: nil)
        case .restartUserspace:
            return .init(systemImage: "arrow.clockwise.circle.fill", tint: Theme.Accents.teal, chevron: nil)
        case .refreshJailbreakApps:
            return .init(systemImage: "app.badge.checkmark.fill", tint: Theme.Accents.green, chevron: nil)
        case .resetMobilePassword:
            return .init(systemImage: "key.fill", tint: Theme.Accents.indigo, chevron: nil)
        case .reinstallSileo:
            return .init(systemImage: "arrow.down.app.fill", tint: Theme.Accents.blue, chevron: nil)
        case .removeJailbreak:
            return .init(systemImage: "trash.fill", tint: Theme.Accents.red, chevron: nil)
        case .confirm:
            return .init(systemImage: "exclamationmark.triangle.fill", tint: Theme.Accents.red, chevron: nil)
        case .back:
            return .init(systemImage: "chevron.backward", tint: Theme.Accents.blue, chevron: nil)
        }
    }
}

extension PostJailbreakHomeView.Screen {
    func title(resourceBundle: Bundle) -> String {
        switch self {
        case .home:
            return "Relaxin"
        case .advancedOptions:
            return String(localized: "Advanced Options", bundle: resourceBundle)
        case .resetAndRemoval:
            return String(localized: "Reset & Remove", bundle: resourceBundle)
        case .credits:
            return String(localized: "Credits", bundle: resourceBundle)
        case let .confirmation(action):
            return action.title(in: resourceBundle)
        }
    }
}

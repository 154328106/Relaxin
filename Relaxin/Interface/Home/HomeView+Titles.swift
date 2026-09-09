import Foundation

extension HomeView.Screen {
    /// Title shown at the top of the glass sub-page nav bar.
    func title(resourceBundle: Bundle) -> String {
        switch self {
        case .home:
            return "Relaxin"
        case .advancedOptions:
            return String(localized: "Advanced Options", bundle: resourceBundle)
        case .maintenance:
            return String(localized: "Maintenance Tools", bundle: resourceBundle)
        case .credits:
            return "更新日志"
        case .jetsamMultiplier:
            return String(localized: "Jetsam Multiplier", bundle: resourceBundle)
        case .confirmation(let action):
            switch action {
            case .removeJailbreak:
                return String(localized: "Remove Jailbreak", bundle: resourceBundle)
            case .resetRelaxin:
                return String(localized: "Reset Relaxin", bundle: resourceBundle)
            }
        case .engine:
            return "Relaxin"
        }
    }
}

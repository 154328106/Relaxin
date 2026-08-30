import CoreGraphics
import Foundation

extension PostJailbreakHomeView {
    static func restartSpringBoardTitle(in resourceBundle: Bundle) -> String {
        if Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true {
            return "重启桌面"
        }
        return String(localized: "Restart SpringBoard", bundle: resourceBundle)
    }

    static func restartUserspaceTitle(in resourceBundle: Bundle) -> String {
        if Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true {
            return "重启空间"
        }
        return String(localized: "Restart Userspace", bundle: resourceBundle)
    }

    enum Screen: Equatable {
        case home
        case advancedOptions
        case resetAndRemoval
        case credits
        case confirmation(ConfirmationAction)

        enum TerminalSurface {
            case home
            case command(String)
            case credits
        }

        var terminalHeight: CGFloat {
            self == .credits
                ? HomeContentLayout.creditsTerminalHeight
                : HomeContentLayout.terminalHeight
        }

        var terminalSurface: TerminalSurface {
            switch self {
            case .home:
                .home
            case .advancedOptions:
                .command("relaxin/advanced-options")
            case .resetAndRemoval:
                .command("relaxin/advanced-options/reset-and-remove")
            case .credits:
                .credits
            case .confirmation:
                .command("relaxin/confirm")
            }
        }

        var backDestination: Screen? {
            switch self {
            case .advancedOptions, .credits:
                .home
            case .resetAndRemoval:
                .advancedOptions
            case let .confirmation(action):
                switch action {
                case .restartSpringBoard, .restartUserspace, .rebootDevice:
                    .home
                case .reinstallSileo, .removeJailbreak:
                    .resetAndRemoval
                }
            case .home:
                nil
            }
        }

        func menuEntries(
            runtimeOptions: PostJailbreakSession.RuntimeOptions,
            canReinstallSileo: Bool,
            supportsIDownload: Bool,
            needsBaseBinUpdate: Bool,
            allowsExternalNavigation: Bool,
            resourceBundle: Bundle
        ) -> [(action: MenuAction, title: String)] {
            switch self {
            case .home:
                return [
                    (
                        .confirm(.restartSpringBoard),
                        PostJailbreakHomeView.restartSpringBoardTitle(
                            in: resourceBundle
                        )
                    ),
                    (
                        .confirm(.restartUserspace),
                        PostJailbreakHomeView.restartUserspaceTitle(
                            in: resourceBundle
                        )
                    ),
                    (
                        .advancedOptions,
                        String(localized: "Advanced Options", bundle: resourceBundle)
                    ),
                    (.credits, String(localized: "Credits", bundle: resourceBundle)),
                ]
            case .advancedOptions:
                var entries: [(MenuAction, String)] = [
                    (
                        .toggleOption(.tweakInjection),
                        ToggleOption.tweakInjection.title(
                            in: runtimeOptions,
                            resourceBundle: resourceBundle
                        )
                    ),
                    (
                        .toggleOption(.appJIT),
                        ToggleOption.appJIT.title(
                            in: runtimeOptions,
                            resourceBundle: resourceBundle
                        )
                    ),
                    (
                        .refreshJailbreakApps,
                        String(
                            localized: "Refresh Jailbreak Apps",
                            bundle: resourceBundle
                        )
                    ),
                ]
                if supportsIDownload {
                    entries.insert(
                        (
                            .toggleOption(.iDownload),
                            ToggleOption.iDownload.title(
                                in: runtimeOptions,
                                resourceBundle: resourceBundle
                            )
                        ),
                        at: 2
                    )
                }
                if needsBaseBinUpdate {
                    entries.append(
                        (
                            .updateBaseBin,
                            String(localized: "Update BaseBin", bundle: resourceBundle)
                        )
                    )
                }
                entries.append(
                    (
                        .resetAndRemoval,
                        String(localized: "Reset & Remove", bundle: resourceBundle)
                    )
                )
                return entries
            case .resetAndRemoval:
                var entries: [(MenuAction, String)] = [
                    (
                        .resetMobilePassword,
                        String(
                            localized: "Reset Mobile Password",
                            bundle: resourceBundle
                        )
                    ),
                ]
                if canReinstallSileo {
                    entries.append(
                        (
                            .confirm(.reinstallSileo),
                            String(localized: "Reinstall Sileo", bundle: resourceBundle)
                        )
                    )
                }
                entries.append(contentsOf: [
                    (
                        .confirm(.removeJailbreak),
                        String(localized: "Remove Jailbreak", bundle: resourceBundle)
                    ),
                ])
                return entries
            case .credits:
                var entries: [(MenuAction, String)] = []
                if allowsExternalNavigation {
                    entries.append(contentsOf: [
                        (
                            .openOwnGoalStudioPicks,
                            String(
                                localized: "OwnGoal Studio's Best",
                                bundle: resourceBundle
                            )
                        ),
                        (
                            .showSoftwareLicense,
                            String(
                                localized: "Software License",
                                bundle: resourceBundle
                            )
                        ),
                    ])
                }
                return entries
            case let .confirmation(action):
                return [
                    (
                        action.menuAction,
                        "\(String(localized: "Execute", bundle: resourceBundle)): \(action.title(in: resourceBundle))"
                    ),
                ]
            }
        }
    }

    enum ToggleOption: CaseIterable, Hashable {
        case tweakInjection
        case appJIT
        case iDownload

        func isEnabled(
            in runtimeOptions: PostJailbreakSession.RuntimeOptions
        ) -> Bool {
            switch self {
            case .tweakInjection:
                runtimeOptions.tweakInjectionEnabled
            case .appJIT:
                runtimeOptions.appJITEnabled
            case .iDownload:
                runtimeOptions.iDownloadEnabled
            }
        }

        func title(
            in runtimeOptions: PostJailbreakSession.RuntimeOptions,
            resourceBundle: Bundle
        ) -> String {
            let name = switch self {
            case .tweakInjection:
                String(localized: "Tweak Injection", bundle: resourceBundle)
            case .appJIT:
                String(localized: "Allow JIT in Apps", bundle: resourceBundle)
            case .iDownload:
                String(localized: "iDownload (Developer Shell)", bundle: resourceBundle)
            }
            let state = isEnabled(in: runtimeOptions)
                ? String(localized: "ON", bundle: resourceBundle)
                : String(localized: "OFF", bundle: resourceBundle)
            return "\(name): \(state)"
        }
    }

    enum ConfirmationAction: Hashable {
        case restartSpringBoard
        case restartUserspace
        case rebootDevice
        case reinstallSileo
        case removeJailbreak

        func title(in resourceBundle: Bundle) -> String {
            switch self {
            case .restartSpringBoard:
                PostJailbreakHomeView.restartSpringBoardTitle(in: resourceBundle)
            case .restartUserspace:
                PostJailbreakHomeView.restartUserspaceTitle(in: resourceBundle)
            case .rebootDevice:
                String(localized: "Restart Device", bundle: resourceBundle)
            case .reinstallSileo:
                String(localized: "Reinstall Sileo", bundle: resourceBundle)
            case .removeJailbreak:
                String(localized: "Remove Jailbreak", bundle: resourceBundle)
            }
        }

        var menuAction: MenuAction {
            switch self {
            case .restartSpringBoard:
                .restartSpringBoard
            case .restartUserspace:
                .restartUserspace
            case .rebootDevice:
                .rebootDevice
            case .reinstallSileo:
                .reinstallSileo
            case .removeJailbreak:
                .removeJailbreak
            }
        }
    }

    enum MenuAction: Hashable {
        case advancedOptions
        case resetAndRemoval
        case credits
        case openOwnGoalStudioPicks
        case showSoftwareLicense
        case toggleOption(ToggleOption)
        case restartSpringBoard
        case restartUserspace
        case rebootDevice
        case refreshJailbreakApps
        case resetMobilePassword
        case reinstallSileo
        case updateBaseBin
        case removeJailbreak
        case confirm(ConfirmationAction)
        case back
    }
}

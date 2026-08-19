import LocalAuthentication
import SwiftUI

struct PostJailbreakHomeView: View {
    private static let ownGoalStudioPicksURL = URL(string: "https://owngoal.dev")!

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @ObservedObject var session: PostJailbreakSession

    let environment: PostJailbreakEnvironment

    @State private var screen = Screen.home
    @State private var alert: Alert?
    @State private var visibleCreditCharacterCount = 0
    @State private var terminalColumnCount = 32

    private var bootLogoUsesDarkAppearance: Bool {
        colorScheme == .dark
    }

    private var terminalOutput: [TerminalOutputLine] {
        guard session.isPerformingAction,
              screen == .confirmation(.removeJailbreak)
        else {
            return session.output
        }
        return session.output + [
            TerminalOutputLine(
                label: String(
                    localized: "Removing the jailbreak. Keep Relaxin in the foreground.",
                    bundle: environment.resourceBundle
                ),
                status: .running
            ),
        ]
    }

    private var terminalText: String {
        guard session.isAvailable else {
            return RelaxinTerminalContent.unavailable(
                resourceBundle: environment.resourceBundle
            )
        }
        switch screen.terminalSurface {
        case .home:
            return RelaxinTerminalContent.home(
                isJailbroken: true,
                resourceBundle: environment.resourceBundle
            )
        case let .command(command):
            return RelaxinTerminalContent.command(
                command: command,
                output: terminalOutput,
                isJailbroken: true,
                terminalWidth: terminalColumnCount,
                resourceBundle: environment.resourceBundle
            )
        case .credits:
            return RelaxinTerminalContent.credits(
                visibleCharacterCount: visibleCreditCharacterCount,
                linksEnabled: environment.interfaceMode.allowsExternalNavigation
            )
        }
    }

    private var terminalAccessibleLinks: [TerminalPresenter.AccessibleLink] {
        guard screen == .credits else { return [] }
        return RelaxinCredits.accessibleLinks(
            linksEnabled: environment.interfaceMode.allowsExternalNavigation
        )
    }

    private var menuItems: [OptionListItem<MenuAction>] {
        guard session.isAvailable else { return [] }
        return screen.menuEntries(
            runtimeOptions: session.runtimeOptions,
            canReinstallSileo: session.canReinstallSileo,
            allowsExternalNavigation: environment.interfaceMode.allowsExternalNavigation,
            resourceBundle: environment.resourceBundle
        ).map { entry in
            OptionListItem(id: entry.action, title: entry.title)
        }
    }

    private var menuShareItems: [MenuAction: URL] {
        guard environment.interfaceMode.allowsExternalNavigation,
              screen == .credits,
              let url = environment.resourceBundle.url(
                  forResource: "Licenses",
                  withExtension: "txt"
              )
        else {
            return [:]
        }
        return [.showSoftwareLicense: url]
    }

    private var enabledToggleOptions: Set<ToggleOption> {
        Set(
            ToggleOption.allCases.filter {
                $0.isEnabled(in: session.runtimeOptions)
            }
        )
    }

    private var homeStatusSubtitle: String {
        "\(DeviceInfo.modelIdentifier) \u{2022} \(DeviceInfo.os)"
    }

    private var homeMenuRows: [DopamineHeroContent.MenuRow] {
        [
            .init(
                id: "advancedOptions",
                systemImage: "slider.horizontal.3",
                title: String(localized: "Advanced Options", bundle: environment.resourceBundle),
                showsChevron: true,
                isEnabled: !session.isPerformingAction,
                tint: Theme.Accents.blue
            ) {
                session.refreshRuntimeOptions()
                screen = .advancedOptions
            },
            .init(
                id: "restartSpringBoard",
                systemImage: "arrow.clockwise",
                title: String(localized: "Restart SpringBoard", bundle: environment.resourceBundle),
                isEnabled: !session.isPerformingAction,
                tint: Theme.Accents.teal
            ) {
                screen = .confirmation(.restartSpringBoard)
            },
            .init(
                id: "restartUserspace",
                systemImage: "arrow.clockwise.circle.fill",
                title: String(localized: "Restart Userspace", bundle: environment.resourceBundle),
                isEnabled: !session.isPerformingAction,
                tint: Theme.Accents.teal
            ) {
                screen = .confirmation(.restartUserspace)
            },
            .init(
                id: "credits",
                systemImage: "heart.fill",
                title: String(localized: "Credits", bundle: environment.resourceBundle),
                showsChevron: true,
                isEnabled: !session.isPerformingAction,
                tint: Theme.Accents.pink
            ) {
                screen = .credits
            },
        ]
    }

    private var heroInfoItems: [DopamineHeroContent.InfoItem] {
        let version = AppInfo.version(in: .main)
        return [
            .init(id: "supported", systemImage: "checkmark.seal.fill", tint: Theme.Accents.green,
                  label: "兼容版本", value: "iOS 16.5.1-17.3.1"),
            .init(id: "version", systemImage: "shippingbox.fill", tint: Theme.Accents.orange,
                  label: "软件版本",
                  value: "\(version) · RootHide"),
            .init(id: "current", systemImage: "iphone", tint: Theme.Accents.blue,
                  label: "当前设备",
                  value: "\(DeviceInfo.shortModelName) \(DeviceInfo.os)"),
            .init(id: "uptime", systemImage: "stopwatch.fill", tint: Theme.Accents.teal,
                  label: "运行时间",
                  value: DeviceInfo.uptimeChinese, liveUptime: true),
        ]
    }

    @ViewBuilder private var homeContent: some View {
        DopamineHeroContent(
            headerTitle: "Relaxin",
            infoItems: heroInfoItems,
            menuRows: homeMenuRows,
            primaryButtonTitle: "已经自由咯",
            // Post-jailbreak: open lock (already unlocked).
            primaryButtonSystemImage: "lock.open.fill",
            // Matches Dopamine's own jailbreak button: once jailbroken it becomes a
            // disabled status display rather than a tappable action.
            isPrimaryButtonEnabled: false,
            onPrimaryAction: {}
        )
    }

    @ViewBuilder private var mainContent: some View {
        if session.isAvailable, screen == .home {
            homeContent
        } else if !session.isAvailable {
            // Terminal-only "unavailable" screen keeps the original layout.
            unavailableContent
        } else {
            glassSubPageContent
        }
    }

    private var unavailableContent: some View {
        HomeContent(
            terminalText: terminalText,
            terminalAccessibleLinks: [],
            terminalHeight: screen.terminalHeight,
            rendersTerminalBackgroundActively: false,
            showsMenu: false,
            menuItems: menuItems,
            preferredMenuAction: nil,
            secondaryMenuActions: [],
            shareItems: [:],
            loadingMenuActions: [],
            isVolumeButtonInputEnabled: false,
            allowsOpeningTerminalLinks: environment.interfaceMode.allowsExternalNavigation,
            onTerminalColumnCountChange: { terminalColumnCount = $0 },
            onSelectMenuItem: performMenuAction
        )
    }

    private var glassSubPageContent: some View {
        let backAction: (() -> Void)? = screen.backDestination.map { destination in
            {
                withAnimation(.easeInOut(duration: 0.25)) {
                    screen = destination
                }
            }
        }

        let rows: [GlassSubPageContent<MenuAction>.Row] = menuItems.map { item in
            let icon = PostJailbreakHomeView.icon(for: item.id)
            return GlassSubPageContent<MenuAction>.Row(
                id: item.id,
                icon: icon,
                title: item.title,
                isLoading: false,
                isDisabled: session.isPerformingAction,
                action: { performMenuAction(item.id) }
            )
        }

        return GlassSubPageContent<MenuAction>(
            title: screen.title(resourceBundle: environment.resourceBundle),
            subtitle: homeStatusSubtitle,
            backAction: backAction,
            rows: rows
        )
    }

    var body: some View {
        mainContent
        // Per-row `isEnabled` already gates taps while the session is
        // performing an action — a container-wide `.disabled` /
        // `.allowsHitTesting` here mysteriously killed every button on the
        // grouped glass home on iOS 16.6.1, so we drop it.
        .task(id: screen == .credits) {
            await animateCreditsIfNeeded()
        }
        .modifier(
            LightImpactFeedbackModifier(trigger: screen) { oldScreen, newScreen in
                oldScreen != newScreen
            }
        )
        .modifier(LightImpactFeedbackModifier(trigger: enabledToggleOptions))
        .alert(item: $alert) { alert in
            switch alert.kind {
            case .notice:
                SwiftUI.Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(
                        Text(
                            String(
                                localized: "OK",
                                bundle: environment.resourceBundle
                            )
                        )
                    )
                )
            case .userspaceRebootRequired:
                SwiftUI.Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(
                        Text(
                            String(
                                localized: "Reboot Now",
                                bundle: environment.resourceBundle
                            )
                        )
                    ) {
                        restartUserspace()
                    },
                    secondaryButton: .cancel(
                        Text(
                            String(
                                localized: "Reboot Later",
                                bundle: environment.resourceBundle
                            )
                        )
                    )
                )
            }
        }
    }

    private func performMenuAction(_ action: MenuAction) {
        switch action {
        case .advancedOptions:
            session.refreshRuntimeOptions()
            screen = .advancedOptions
        case .resetAndRemoval:
            screen = .resetAndRemoval
        case .credits:
            screen = .credits
        case .openOwnGoalStudioPicks:
            guard environment.interfaceMode.allowsExternalNavigation else { return }
            openURL(Self.ownGoalStudioPicksURL)
        case .showSoftwareLicense:
            guard environment.interfaceMode.allowsExternalNavigation else { return }
            showSoftwareLicenseUnavailable()
        case let .toggleOption(option):
            toggle(option)
        case let .confirm(action):
            screen = .confirmation(action)
        case .restartSpringBoard:
            session.perform(.restartSpringBoard)
        case .restartUserspace:
            restartUserspace()
        case .refreshJailbreakApps:
            session.perform(.refreshJailbreakApps)
        case .resetMobilePassword:
            authenticateForPasswordReset()
        case .reinstallSileo:
            guard session.canReinstallSileo else { return }
            session.reinstallSileo()
        case .removeJailbreak:
            session.perform(.removeJailbreak)
        case .back:
            if let destination = screen.backDestination {
                screen = destination
            }
        }
    }

    private func toggle(_ option: ToggleOption) {
        let enabled = !option.isEnabled(in: session.runtimeOptions)
        switch option {
        case .tweakInjection:
            session.setTweakInjectionEnabled(enabled)
            alert = .userspaceRebootRequired(in: environment.resourceBundle)
        case .appJIT:
            session.setAppJITEnabled(enabled)
        }
    }

    private func restartUserspace() {
        session.perform(
            .restartUserspace(darkAppearance: bootLogoUsesDarkAppearance)
        )
    }

    private func authenticateForPasswordReset() {
        let context = LAContext()
        var authenticationError: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &authenticationError
        ) else {
            session.perform(.resetMobilePassword)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: String(
                localized: "Authentication is required to change your mobile password.",
                bundle: environment.resourceBundle
            )
        ) { success, _ in
            guard success else { return }
            Task { @MainActor in
                session.perform(.resetMobilePassword)
            }
        }
    }

    private func showSoftwareLicenseUnavailable() {
        guard environment.interfaceMode.allowsExternalNavigation else { return }
        let message = String(
            localized: "The software license file is missing.",
            bundle: environment.resourceBundle
        )
        AppLog.error(Self.self, message)
        alert = Alert(
            title: String(
                localized: "Software License Unavailable",
                bundle: environment.resourceBundle
            ),
            message: message
        )
    }

    private func animateCreditsIfNeeded() async {
        visibleCreditCharacterCount = 0
        guard screen == .credits else { return }

        var characterCount = 0
        while characterCount < RelaxinCredits.characterCount {
            do {
                try await Task.sleep(
                    for: .milliseconds(.random(in: 15 ... 35))
                )
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            characterCount = min(
                characterCount + .random(in: 1 ... 4),
                RelaxinCredits.characterCount
            )
            visibleCreditCharacterCount = characterCount
        }
    }
}

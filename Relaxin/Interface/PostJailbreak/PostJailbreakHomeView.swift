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
    @StateObject private var healthSession: HealthSession
    @State private var visibleCreditCharacterCount = 0
    @State private var terminalColumnCount = 32

    // A private @StateObject suppresses the memberwise initializer, so the
    // three call sites keep working through this explicit one.
    init(session: PostJailbreakSession, environment: PostJailbreakEnvironment) {
        _session = ObservedObject(wrappedValue: session)
        self.environment = environment
        _healthSession = StateObject(
            wrappedValue: HealthSession(resourceBundle: environment.resourceBundle)
        )
    }

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
            return RelaxinTerminalContent.changelog(
                visibleCharacterCount: visibleCreditCharacterCount
            )
        }
    }

    private var terminalAccessibleLinks: [TerminalPresenter.AccessibleLink] {
        []
    }

    private var menuItems: [OptionListItem<MenuAction>] {
        guard session.isAvailable else { return [] }
        return screen.menuEntries(
            runtimeOptions: session.runtimeOptions,
            canReinstallPackageManagers: session.canReinstallPackageManagers,
            supportsIDownload: session.supportsIDownload,
            needsBaseBinUpdate: session.needsBaseBinUpdate,
            allowsExternalNavigation: environment.interfaceMode.allowsExternalNavigation,
            resourceBundle: environment.resourceBundle
        ).map { entry in
            OptionListItem(id: entry.action, title: entry.title)
        }
    }

    private var menuShareItems: [MenuAction: URL] {
        guard environment.interfaceMode.allowsExternalNavigation,
              screen == .advancedOptions
        else {
            return [:]
        }
        // Licenses.txt lives in the app's main bundle; environment.resourceBundle
        // points at the RelaxinEngine framework which doesn't carry it.
        guard let url = Bundle.main.url(forResource: "Licenses", withExtension: "txt")
            ?? environment.resourceBundle.url(forResource: "Licenses", withExtension: "txt")
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

    /// Direct navigation — no runloop defer needed now that mainContent is
    /// wrapped in ZStack+Group (the real cure for the iOS 16.6.1 tap-eaten
    /// bug). Skipping the Task hop makes taps feel instant instead of the
    /// previous half-beat lag.
    private func navigate(to target: Screen, refreshRuntimeOptions: Bool = false) {
        if refreshRuntimeOptions {
            session.refreshRuntimeOptions()
        }
        withAnimation(Theme.screenAnimation) {
            screen = target
        }
    }

    private var homeMenuRows: [DopamineHeroContent.MenuRow] {
        // 一比一 Dopamine RH（越狱后）：与未越狱同款菜单，重启三项与健康检测此时可点。
        [
            .init(id: "settings", systemImage: "gearshape", title: "设置详情管理",
                  showsChevron: true, isEnabled: !session.isPerformingAction) {
                navigate(to: .advancedOptions, refreshRuntimeOptions: true)
            },
            .init(id: "restartSpringBoard", systemImage: "arrow.clockwise",
                  title: "重启桌面总控", isEnabled: !session.isPerformingAction) {
                navigate(to: .confirmation(.restartSpringBoard))
            },
            .init(id: "restartUserspace", systemImage: "arrow.triangle.2.circlepath",
                  title: "重启用户空间", isEnabled: !session.isPerformingAction) {
                navigate(to: .confirmation(.restartUserspace))
            },
            .init(id: "rebootDevice", systemImage: "power",
                  title: "重启本机设备", isEnabled: !session.isPerformingAction) {
                navigate(to: .confirmation(.rebootDevice))
            },
            .init(id: "health", systemImage: "heart.text.square",
                  title: "健康状态检测", showsChevron: true,
                  isEnabled: !session.isPerformingAction) {
                navigate(to: .health)
            },
        ]
    }

    @ViewBuilder private var homeContent: some View {
        DopamineHeroContent(
            headerTitle: "Relaxin",
            subtitle: "16.5-18.7.1/26.0-26.0.1",
            showsUptime: true,
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

    private var mainContent: some View {
        // ZStack + Group wrapper is load-bearing: on iOS 16.6.1 the raw
        // three-branch if/else-if/else returned from a @ViewBuilder computed
        // property would let @State writes go through but not re-evaluate
        // this conditional, so taps looked dead. Wrapping in a stable outer
        // container (ZStack) makes SwiftUI reliably re-render the branch.
        ZStack {
            // 常驻背景：不参与转场，页面只负责内容。
            LiquidBackground()

            Group {
                if session.isAvailable, screen == .home {
                    homeContent
                        .transition(.opacity)
                } else if !session.isAvailable {
                    unavailableContent
                        .transition(.opacity)
                } else if screen == .health {
                    healthContent
                        .transition(Theme.subPageTransition)
                } else {
                    glassSubPageContent
                        .transition(Theme.subPageTransition)
                }
            }
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
                withAnimation(Theme.screenAnimation) {
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
            rows: rows,
            shareItems: menuShareItems,
            bodyLines: screen == .credits ? RelaxinChangelog.lines : []
        )
    }

    private var healthContent: some View {
        GlassHealthContent(
            subtitle: homeStatusSubtitle,
            backAction: {
                withAnimation(Theme.screenAnimation) {
                    screen = .home
                }
            },
            items: healthSession.items,
            isScanning: healthSession.isScanning,
            lastScanAt: healthSession.lastScanAt,
            repairingID: healthSession.repairingID,
            onRescan: { healthSession.scan() },
            onRepair: { healthSession.repair($0) }
        )
        // Health is a point-in-time read, so re-scan on every entry rather
        // than showing whatever the last visit left behind.
        .onAppear { healthSession.scan() }
        .onChange(of: healthSession.notice) { notice in
            guard let notice else { return }
            alert = Alert(title: "健康状态检测", message: notice)
            healthSession.notice = nil
        }
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
            case .deviceRestartRequired:
                SwiftUI.Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(
                        Text(
                            String(
                                localized: "Restart Device",
                                bundle: environment.resourceBundle
                            )
                        )
                    ) {
                        session.perform(.rebootDevice)
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
        .onChange(of: session.lastCompletedAction) { action in
            guard action == .updateBaseBin else { return }
            session.consumeLastCompletedAction()
            alert = .deviceRestartRequired(in: environment.resourceBundle)
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
        case .rebootDevice:
            session.perform(.rebootDevice)
        case .refreshJailbreakApps:
            session.perform(.refreshJailbreakApps)
        case .resetMobilePassword:
            authenticateForPasswordReset()
        case .reinstallSileo:
            guard session.canReinstallPackageManagers else { return }
            session.reinstall(.sileo)
        case .reinstallIrisin:
            guard session.canReinstallPackageManagers else { return }
            session.reinstall(.irisin)
        case .updateBaseBin:
            session.perform(.updateBaseBin)
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
        case .iDownload:
            session.setIDownloadEnabled(enabled)
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
        while characterCount < RelaxinChangelog.characterCount {
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
                RelaxinChangelog.characterCount
            )
            visibleCreditCharacterCount = characterCount
        }
    }
}

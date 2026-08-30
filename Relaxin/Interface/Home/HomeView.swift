import Foundation
import SwiftUI

struct HomeView: View {
    let runtime: RelaxinRuntime

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) var openURL
    @StateObject var engineSession: EngineSession
    @State var screen = Screen.home
    @State var configuration: JailbreakConfiguration
    @State var alert: Presentation.Alert?
    @State var logExportState = LogExportState.idle
    @State private var visibleCreditCharacterCount = 0
    @State private var terminalColumnCount = 32
    @State private var jailbreakState = JailbreakStateProbe.State.none

    init(runtime: RelaxinRuntime) {
        self.runtime = runtime
        _engineSession = StateObject(wrappedValue: EngineSession(runtime: runtime))
        _configuration = State(
            initialValue: JailbreakConfiguration(defaults: runtime.defaults)
        )
    }

    var bootLogoUsesDarkAppearance: Bool {
        colorScheme == .dark
    }

    var supportsIDownload: Bool {
        runtime.resourceBundle.url(
            forResource: "libkrw-relaxin",
            withExtension: "deb"
        ) != nil
    }

    private var enabledToggleOptions: Set<ToggleOption> {
        Set(
            ToggleOption.allCases.filter {
                $0.isEnabled(in: configuration)
            }
        )
    }

    private var terminalText: String {
        switch screen.terminalSurface {
        case .home:
            RelaxinTerminalContent.home(
                isJailbroken: false,
                resourceBundle: runtime.resourceBundle
            )
        case let .command(command):
            RelaxinTerminalContent.command(
                command: command,
                output: engineSession.output,
                isJailbroken: false,
                terminalWidth: terminalColumnCount,
                resourceBundle: runtime.resourceBundle
            )
        case .credits:
            RelaxinTerminalContent.credits(
                visibleCharacterCount: visibleCreditCharacterCount,
                linksEnabled: runtime.interfaceMode.allowsExternalNavigation
            )
        case .engine:
            if case .idle = engineSession.phase {
                RelaxinTerminalContent.home(
                    isJailbroken: false,
                    resourceBundle: runtime.resourceBundle
                )
            } else {
                RelaxinTerminalContent.running(
                    output: engineSession.output,
                    isJailbroken: false,
                    terminalWidth: terminalColumnCount,
                    resourceBundle: runtime.resourceBundle
                )
            }
        }
    }

    private var terminalAccessibleLinks: [TerminalPresenter.AccessibleLink] {
        guard screen == .credits else { return [] }
        return RelaxinCredits.accessibleLinks(
            linksEnabled: runtime.interfaceMode.allowsExternalNavigation
        )
    }

    private var rendersTerminalBackgroundActively: Bool {
        guard screen == .engine,
              !isShowingFailure,
              let runtimeProfile = JailbreakTarget.current.runtimeProfile
        else {
            return false
        }
        switch runtimeProfile {
        case .pplDMAA12, .pplGFXA13:
            return false
        case .pplGFXA14M1, .gfxA15M2, .gfxA16, .sptmGFXA17:
            return true
        }
    }

    private var engineFailure: EngineSession.Failure? {
        guard case let .failed(failure) = engineSession.phase else { return nil }
        return failure
    }

    private var isShowingFailure: Bool {
        engineFailure != nil
    }

    private var homeStatusSubtitle: String {
        "\(DeviceInfo.modelIdentifier) \u{2022} \(DeviceInfo.os)"
    }

    private var homePrimaryButtonTitle: String {
        configuration.removeJailbreakEnabled
            ? String(localized: "Remove Jailbreak", bundle: runtime.resourceBundle)
            : "获取自由吧"
    }

    private var homeMenuRows: [DopamineHeroContent.MenuRow] {
        var rows: [DopamineHeroContent.MenuRow] = [
            .init(
                id: "advancedOptions",
                systemImage: "slider.horizontal.3",
                title: String(localized: "Advanced Options", bundle: runtime.resourceBundle),
                showsChevron: true,
                tint: Theme.Accents.blue
            ) {
                screen = .advancedOptions
            },
        ]
        if runtime.interfaceMode.showsMaintenance {
            rows.append(
                .init(
                    id: "maintenance",
                    systemImage: "wrench.and.screwdriver.fill",
                    title: String(localized: "Maintenance Tools", bundle: runtime.resourceBundle),
                    showsChevron: true,
                    tint: Theme.Accents.orange
                ) {
                    screen = .maintenance
                }
            )
        }
        rows.append(
            .init(
                id: "credits",
                systemImage: "heart.fill",
                title: String(localized: "Credits", bundle: runtime.resourceBundle),
                showsChevron: true,
                tint: Theme.Accents.pink
            ) {
                screen = .credits
            }
        )
        return rows
    }

    private var heroInfoItems: [DopamineHeroContent.InfoItem] {
        // Bundle.main holds the app's own Info.plist with the marketing
        // version (runtime.resourceBundle points at the RelaxinEngine
        // framework whose version stays at 0.0.0).
        let version = AppInfo.version(in: .main)
        return [
            .init(id: "supported", systemImage: "checkmark.seal.fill", tint: Theme.Accents.green,
                  label: "兼容版本", value: "iOS 16.5.1-17.3.1"),
            .init(id: "version", systemImage: "shippingbox.fill", tint: Theme.Accents.orange,
                  label: "软件版本",
                  value: "\(version)·RootHide"),
            .init(id: "current", systemImage: "iphone", tint: Theme.Accents.blue,
                  label: "当前设备",
                  // Raw model identifier (iPhone15,3), not the marketing name.
                  value: "\(DeviceInfo.modelIdentifier) \(DeviceInfo.os)"),
            // Device uptime only says something worth reading once the
            // jailbreak is live; before that the cell reports the probed
            // jailbreak state instead.
            jailbreakInfoItem,
        ]
    }

    private var jailbreakInfoItem: DopamineHeroContent.InfoItem {
        switch jailbreakState {
        case .active:
            DopamineHeroContent.InfoItem(
                id: "uptime", systemImage: "stopwatch.fill", tint: Theme.Accents.teal,
                label: "运行时间", value: DeviceInfo.uptimeChinese, liveUptime: true
            )
        case .installedInactive:
            DopamineHeroContent.InfoItem(
                id: "jailbreakState", systemImage: "arrow.clockwise.circle.fill",
                tint: Theme.Accents.indigo,
                label: "越狱状态", value: "待重新越狱"
            )
        case .none:
            DopamineHeroContent.InfoItem(
                id: "jailbreakState", systemImage: "lock.fill", tint: Theme.Accents.orange,
                label: "越狱状态", value: "当前设备未越狱"
            )
        }
    }

    /// Re-probes the device: a live RootHide runtime, else a finished
    /// bootstrap sitting on disk (what a reboot leaves behind), else nothing.
    /// Cheap enough — one `jbclient` call plus one directory listing.
    func refreshJailbreakState() {
        let state = JailbreakStateProbe.state(
            isRuntimeActive: engineSession.postJailbreakSession.probeRuntimeActive()
        )
        jailbreakState = state
        // Nothing installed means nothing to remove: drop a stale request so
        // the primary button can't stay stuck on "Remove Jailbreak" after the
        // toggle that set it has been hidden.
        if state == .none, configuration.removeJailbreakEnabled {
            configuration.removeJailbreakEnabled = false
        }
    }

    /// Whether a removal is worth offering at all — there has to be a
    /// bootstrap on disk for it to have anything to do.
    var canRemoveJailbreak: Bool {
        jailbreakState != .none
    }

    @ViewBuilder private var homeContent: some View {
        DopamineHeroContent(
            headerTitle: "Relaxin",
            infoItems: heroInfoItems,
            menuRows: homeMenuRows,
            primaryButtonTitle: homePrimaryButtonTitle,
            // Pre-jailbreak: closed lock (you're about to unlock).
            primaryButtonSystemImage: "lock.fill",
            isPrimaryButtonEnabled: {
                if case .idle = engineSession.phase { return true }
                return false
            }(),
            onPrimaryAction: {
                // Mirrors the `.jailbreak` menu action: removal requires an
                // explicit confirmation screen before the engine runs.
                if configuration.removeJailbreakEnabled {
                    screen = .confirmation(.removeJailbreak)
                } else {
                    startEngine()
                }
            }
        )
    }

    @ViewBuilder private var primaryContent: some View {
        switch screen {
        case .home:
            homeContent
        case .engine:
            engineContent
        default:
            glassSubPageContent
        }
    }

    /// Phase headline for the engine screen's status card.
    private var engineStatusTitle: String {
        switch engineSession.phase {
        case .idle:
            "准备就绪"
        case .running:
            "正在越狱"
        case .finished:
            "越狱完成"
        case .failed:
            "越狱失败"
        }
    }

    /// Label of the step the engine is on, monospaced under the headline.
    private var engineStatusDetail: String? {
        engineSession.output.last { $0.status == .running }?.label
            ?? engineSession.output.last?.label
    }

    /// Live progress, derived from the most recent output line that carries a
    /// position/count pair — the engine reports those as "03/12"-style steps.
    private var engineProgress: (step: String, value: Double)? {
        let line = engineSession.output.last {
            $0.position != nil && $0.count != nil
        }
        guard let position = line?.position,
              let count = line?.count,
              count > 0
        else { return nil }
        return (
            String(format: "%02d/%02d", position, count),
            min(1, Double(position) / Double(count))
        )
    }

    /// Full-screen glass wrapper around the running terminal (engine phase).
    private var engineContent: some View {
        let progress = engineProgress
        return GlassEngineContent(
            title: screen.title(resourceBundle: runtime.resourceBundle),
            terminalText: terminalText,
            statusTitle: engineStatusTitle,
            statusDetail: engineStatusDetail,
            progress: progress?.value,
            stepText: progress?.step,
            isFinished: {
                if case .finished = engineSession.phase { return true }
                return false
            }(),
            isFailed: isShowingFailure,
            onColumnCountChange: { terminalColumnCount = $0 }
        )
    }

    /// Liquid-glass sub-page (advanced options / maintenance / credits /
    /// jetsam / confirmation). Replaces the old terminal+plain-menu layout
    /// and gives every sub-page a proper back button up top instead of a
    /// buried "Back" entry.
    private var glassSubPageContent: some View {
        let backAction: (() -> Void)? = screen.backDestination.map { destination in
            {
                withAnimation(.easeInOut(duration: 0.25)) {
                    screen = destination
                }
            }
        }

        let rows: [GlassSubPageContent.Row] = menuItems.map { item in
            let icon = HomeView.icon(for: item.id)
            return GlassSubPageContent.Row(
                id: item.id,
                icon: icon,
                title: item.title,
                isLoading: loadingMenuActions.contains(item.id),
                isDisabled: false,
                action: { performMenuAction(item.id) }
            )
        }

        return GlassSubPageContent(
            title: screen.title(resourceBundle: runtime.resourceBundle),
            subtitle: homeStatusSubtitle,
            backAction: backAction,
            rows: rows,
            selectedID: preferredMenuAction,
            shareItems: menuShareItems
        )
    }

    @ViewBuilder private var presentedContent: some View {
        if #available(iOS 17.0, *) {
            if let failure = engineFailure {
                FailureView(
                    failure: failure,
                    resourceBundle: runtime.resourceBundle
                )
            } else {
                primaryContent
            }
        } else {
            ZStack {
                primaryContent
                    .allowsHitTesting(!isShowingFailure)
                    .accessibilityHidden(isShowingFailure)

                if let failure = engineFailure {
                    FailureView(
                        failure: failure,
                        resourceBundle: runtime.resourceBundle
                    )
                    .zIndex(1)
                }
            }
        }
    }

    @ViewBuilder private var productContent: some View {
        if runtime.interfaceMode.showsPostJailbreakInterface,
           engineSession.postJailbreakSession.isAvailable,
           !isShowingFailure
        {
            PostJailbreakHomeView(
                session: engineSession.postJailbreakSession,
                environment: runtime.postJailbreakEnvironment
            )
        } else {
            presentedContent
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
                                        bundle: runtime.resourceBundle
                                    )
                                )
                            )
                        )
                    case .jailbreakRemovalComplete:
                        SwiftUI.Alert(
                            title: Text(alert.title),
                            message: Text(alert.message),
                            dismissButton: .default(
                                Text(
                                    String(
                                        localized: "OK",
                                        bundle: runtime.resourceBundle
                                    )
                                )
                            ) {
                                suspendApplication()
                            }
                        )
                    }
                }
        }
    }

    var body: some View {
        productContent
            .task {
                refreshJailbreakState()
                guard runtime.interfaceMode == .full else { return }
                engineSession.postJailbreakSession.refreshAvailability()
            }
            .onChange(of: screen) { newScreen in
                // Coming back to the hero page after the engine ran — the
                // state on disk may well have changed underneath us.
                guard newScreen == .home else { return }
                refreshJailbreakState()
            }
            .modifier(
                LightImpactFeedbackModifier(trigger: screen) { oldScreen, newScreen in
                    oldScreen != newScreen && newScreen.showsMenu
                }
            )
            .modifier(LightImpactFeedbackModifier(trigger: enabledToggleOptions))
        #if DEBUG
            .modifier(
                LightImpactFeedbackModifier(
                    trigger: engineSession.postJailbreakSession.isAvailable
                )
            )
        #endif
            .task(id: screen == .credits) {
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
}

#Preview {
    NavigationStack {
        HomeView(runtime: .native)
    }
}

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
            RelaxinTerminalContent.changelog(
                visibleCharacterCount: visibleCreditCharacterCount
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
        []
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
        // 一比一 Dopamine RH（未越狱）：设置在最上、重启三项灰色占位在中间、
        // 健康检测在最下。重启与健康检测都要越狱后才可点，这里未越狱恒灰。
        [
            .init(
                id: "settings",
                systemImage: "gearshape",
                title: "设置详情管理",
                showsChevron: true
            ) {
                withAnimation(Theme.screenAnimation) {
                    screen = .advancedOptions
                }
            },
            .init(id: "restartSpringBoard", systemImage: "arrow.clockwise",
                  title: "重启桌面总控", isEnabled: false) {},
            .init(id: "restartUserspace", systemImage: "arrow.triangle.2.circlepath",
                  title: "重启用户空间", isEnabled: false) {},
            .init(id: "restartDevice", systemImage: "power",
                  title: "重启本机设备", isEnabled: false) {},
            // 健康检测要读 jbroot，未越狱无从查起 —— 和上面三项一样恒灰。
            .init(id: "health", systemImage: "heart.text.square",
                  title: "健康状态检测", isEnabled: false) {},
        ]
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
            subtitle: "16.5-18.7.1/26.0-26.0.1",
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
                withAnimation(Theme.screenAnimation) {
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
            shareItems: menuShareItems,
            bodyLines: screen == .credits ? RelaxinChangelog.lines : []
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
}

#Preview {
    NavigationStack {
        HomeView(runtime: .native)
    }
}

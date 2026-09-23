import Combine
import Foundation
import RelaxinPostJailbreak

@MainActor
final class PostJailbreakSession: ObservableObject {
    /// 0.5.4 起可选包管理器：Sileo 和 Irisin 都能单独重装。
    enum PackageManager: Hashable {
        case sileo
        case irisin
    }

    typealias AsyncOperation = @MainActor (
        _ output: @escaping (String) -> Void
    ) async throws -> Void

    typealias ReinstallPackageManagerAction = @MainActor (
        _ packageManager: PackageManager,
        _ output: @escaping (String) -> Void
    ) async throws -> Void

    @Published private(set) var isAvailable = false
    @Published private(set) var runtimeOptions = RuntimeOptions()
    @Published private(set) var needsBaseBinUpdate = false
    @Published private(set) var output: [TerminalOutputLine] = []
    @Published private(set) var isPerformingAction = false
    @Published private(set) var lastCompletedAction: Action?

    let environment: PostJailbreakEnvironment
    private let controller: RLXPostJailbreakController
    private let reinstallPackageManagerAction: ReinstallPackageManagerAction?
    #if DEBUG
        private var debugAvailableOverride: Bool?
    #endif

    init(
        environment: PostJailbreakEnvironment,
        controller: RLXPostJailbreakController,
        reinstallPackageManager: ReinstallPackageManagerAction? = nil
    ) {
        self.environment = environment
        self.controller = controller
        reinstallPackageManagerAction = reinstallPackageManager
        switch environment.interfaceMode {
        case .full:
            isAvailable = controller.hasActiveRootHideRuntime()
        case .lite:
            isAvailable = true
        case .overlay:
            isAvailable = false
        }
    }

    convenience init(environment: PostJailbreakEnvironment) {
        self.init(
            environment: environment,
            controller: RLXPostJailbreakController(
                resourceBundle: environment.resourceBundle
            )
        )
    }

    var canReinstallPackageManagers: Bool {
        environment.interfaceMode.allowsSileoReinstallation
            && reinstallPackageManagerAction != nil
    }

    var supportsIDownload: Bool {
        environment.resourceBundle.url(
            forResource: "libkrw-relaxin",
            withExtension: "deb"
        ) != nil
    }

    /// Read-only device probe: is a RootHide runtime live right now?
    ///
    /// Unlike `refreshAvailability()` this touches no published state and is
    /// not gated on the interface mode, so the pre-jailbreak hero card can
    /// call it without flipping the whole UI over to the post-jailbreak view.
    func probeRuntimeActive() -> Bool {
        controller.isAvailable()
    }

    func refreshAvailability() {
        #if DEBUG
            if let debugAvailableOverride {
                isAvailable = debugAvailableOverride
                return
            }
        #endif
        isAvailable = controller.isAvailable()
        if isAvailable {
            refreshRuntimeOptions()
        }
    }

    func refreshRuntimeOptions() {
        guard isAvailable else { return }
        runtimeOptions = RuntimeOptions(
            tweakInjectionEnabled: controller.tweakInjectionEnabled(),
            appJITEnabled: controller.appJITEnabled(),
            iDownloadEnabled: supportsIDownload
                && controller.iDownloadEnabled()
        )
        needsBaseBinUpdate = supportsIDownload
            && !controller.installedBaseBinMatchesBundledVersion()
    }

    func setTweakInjectionEnabled(_ enabled: Bool) {
        guard isAvailable else { return }
        controller.setTweakInjectionEnabled(enabled)
        runtimeOptions.tweakInjectionEnabled = enabled
    }

    func setAppJITEnabled(_ enabled: Bool) {
        guard isAvailable else { return }
        controller.setAppJITEnabled(enabled)
        runtimeOptions.appJITEnabled = enabled
    }

    func setIDownloadEnabled(_ enabled: Bool) {
        guard isAvailable, supportsIDownload else { return }
        controller.setIDownloadEnabled(enabled)
        runtimeOptions.iDownloadEnabled = enabled
    }

    func perform(_ action: Action) {
        guard isAvailable, !isPerformingAction else { return }
        performOperation(completedAction: action) { [controller] outputHandler in
            try await controller.perform(
                action: action.postJailbreakAction,
                arguments: action.postJailbreakArguments,
                output: outputHandler
            )
        }
    }

    func reinstall(_ packageManager: PackageManager) {
        guard canReinstallPackageManagers, let reinstallPackageManagerAction else { return }
        performOperation { outputHandler in
            try await reinstallPackageManagerAction(packageManager, outputHandler)
        }
    }

    func consumeLastCompletedAction() {
        lastCompletedAction = nil
    }

    private func performOperation(
        completedAction: Action? = nil,
        _ operation: @escaping AsyncOperation
    ) {
        guard isAvailable, !isPerformingAction else { return }
        isPerformingAction = true
        Task { [self] in
            defer { isPerformingAction = false }
            do {
                let outputHandler: (String) -> Void = { message in
                    if Thread.isMainThread {
                        self.append(
                            TerminalOutputLine(label: message, status: .info)
                        )
                    } else {
                        DispatchQueue.main.sync {
                            self.append(
                                TerminalOutputLine(label: message, status: .info)
                            )
                        }
                    }
                }
                try await operation(outputHandler)
                refreshAvailability()
                lastCompletedAction = completedAction
            } catch {
                append(
                    TerminalOutputLine(
                        label: error.localizedDescription,
                        status: .failed
                    )
                )
            }
        }
    }

    private func append(_ line: TerminalOutputLine) {
        output.append(line)
    }

    #if DEBUG
        func debugSetAvailable(_ value: Bool) {
            debugAvailableOverride = value
            isAvailable = value
            AppLog.info(Self.self, "debug post-jailbreak available=\(value ? 1 : 0)")
        }
    #endif
}

extension PostJailbreakSession {
    enum Action: Equatable {
        case restartSpringBoard
        case restartUserspace(darkAppearance: Bool)
        case refreshJailbreakApps
        case resetMobilePassword
        case rebootDevice
        case removeJailbreak
        case updateBaseBin
    }

    struct RuntimeOptions: Equatable {
        var tweakInjectionEnabled = true
        var appJITEnabled = false
        var iDownloadEnabled = false
    }
}

private extension PostJailbreakSession.Action {
    var postJailbreakAction: RLXPostJailbreakAction {
        switch self {
        case .restartSpringBoard:
            .restartSpringBoard
        case .restartUserspace:
            .restartUserspace
        case .refreshJailbreakApps:
            .refreshJailbreakApps
        case .resetMobilePassword:
            .resetMobilePassword
        case .rebootDevice:
            .restartDevice
        case .removeJailbreak:
            .removeJailbreak
        case .updateBaseBin:
            .updateBaseBin
        }
    }

    var postJailbreakArguments: [RLXPostJailbreakActionArgumentKey: String]? {
        guard case let .restartUserspace(darkAppearance) = self else {
            return nil
        }
        return [
            .bootLogoDarkAppearanceKey: darkAppearance ? "true" : "false",
        ]
    }
}

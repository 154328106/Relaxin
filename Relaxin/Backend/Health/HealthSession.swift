import Combine
import Foundation
import RelaxinPostJailbreak

/// Drives the health page: one read-only scan of the RootHide environment plus
/// the narrowly scoped repairs the manager offers. Both touch LaunchServices
/// and the jbroot filesystem, so they run off the main queue.
@MainActor
final class HealthSession: ObservableObject {
    struct Item: Identifiable, Equatable {
        let id: String
        let title: String
        let detail: String
        let state: RLXHealthState
        let canRepair: Bool
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var isScanning = false
    @Published private(set) var repairingID: String?
    @Published var notice: String?

    private let manager: RLXHealthManager

    // nonisolated so SwiftUI can build it inside a View initializer.
    nonisolated init(resourceBundle: Bundle) {
        manager = RLXHealthManager(resourceBundle: resourceBundle)
    }

    var isBusy: Bool {
        isScanning || repairingID != nil
    }

    func scan() {
        guard !isBusy else { return }
        isScanning = true
        let manager = manager
        Task.detached(priority: .userInitiated) {
            let scanned = manager.scanHealth().map { Item($0) }
            await MainActor.run {
                self.items = scanned
                self.isScanning = false
            }
        }
    }

    func repair(_ id: String) {
        guard !isBusy else { return }
        repairingID = id
        let manager = manager
        Task.detached(priority: .userInitiated) {
            let error = manager.repairItem(withIdentifier: id)
            let rescanned = manager.scanHealth().map { Item($0) }
            await MainActor.run {
                self.items = rescanned
                self.repairingID = nil
                self.notice = error?.localizedDescription ?? "修复完成"
            }
        }
    }
}

private extension HealthSession.Item {
    init(_ item: RLXHealthItem) {
        self.init(
            id: item.identifier,
            title: item.title,
            detail: item.detail,
            state: item.state,
            canRepair: item.canRepair
        )
    }
}

extension RLXHealthState {
    /// Status pill text. Mirrors Dopamine's colored-dot vocabulary so the two
    /// apps read the same way.
    var badgeTitle: String {
        switch self {
        case .healthy: "正常"
        case .warning: "注意"
        case .repairable: "可修复"
        case .conflict: "冲突"
        case .disabled: "已停用"
        case .unknown: "未知"
        @unknown default: "未知"
        }
    }
}

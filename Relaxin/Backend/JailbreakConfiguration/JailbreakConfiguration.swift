import Foundation
import RelaxinEngine

/// App-owned jailbreak options passed into `RLXEngine` as a manifest snapshot.
struct JailbreakConfiguration {
    private enum StorageKey {
        static let tweakInjectionEnabled = "tweakInjectionEnabled"
        static let appJITEnabled = "appJITEnabled"
        static let iDownloadEnabled = "iDownloadEnabled"
        static let jetsamMultiplier = "jetsamMultiplier"
        static let removeJailbreakEnabled = "removeJailbreakEnabled"
    }

    private let defaults: UserDefaults

    var tweakInjectionEnabled: Bool {
        didSet {
            defaults.set(
                tweakInjectionEnabled,
                forKey: StorageKey.tweakInjectionEnabled
            )
        }
    }

    var appJITEnabled: Bool {
        didSet {
            defaults.set(
                appJITEnabled,
                forKey: StorageKey.appJITEnabled
            )
        }
    }

    var iDownloadEnabled: Bool {
        didSet {
            defaults.set(
                iDownloadEnabled,
                forKey: StorageKey.iDownloadEnabled
            )
        }
    }

    var jetsamMultiplier: JetsamMultiplier {
        didSet {
            defaults.set(
                jetsamMultiplier.rawValue,
                forKey: StorageKey.jetsamMultiplier
            )
        }
    }

    var removeJailbreakEnabled: Bool {
        didSet {
            defaults.set(
                removeJailbreakEnabled,
                forKey: StorageKey.removeJailbreakEnabled
            )
        }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        defaults.register(defaults: [
            StorageKey.tweakInjectionEnabled: true,
            StorageKey.appJITEnabled: false,
            StorageKey.iDownloadEnabled: false,
            StorageKey.jetsamMultiplier: JetsamMultiplier.three.rawValue,
            StorageKey.removeJailbreakEnabled: false,
        ])
        tweakInjectionEnabled = defaults.bool(
            forKey: StorageKey.tweakInjectionEnabled
        )
        appJITEnabled = defaults.bool(forKey: StorageKey.appJITEnabled)
        iDownloadEnabled = defaults.bool(forKey: StorageKey.iDownloadEnabled)
        jetsamMultiplier = defaults
            .string(forKey: StorageKey.jetsamMultiplier)
            .flatMap(JetsamMultiplier.init(rawValue:))
            ?? .three
        removeJailbreakEnabled = defaults.bool(
            forKey: StorageKey.removeJailbreakEnabled
        )
    }

    func manifest(for target: JailbreakTarget) throws -> [RLXEngineManifestKey: String] {
        var manifest = try target.confirmedManifest()
        manifest[.tweakInjectionEnabledKey] = tweakInjectionEnabled ? "true" : "false"
        manifest[.appJITEnabledKey] = appJITEnabled ? "true" : "false"
        manifest[.iDownloadEnabledKey] = iDownloadEnabled ? "true" : "false"
        manifest[.jetsamMultiplierKey] = jetsamMultiplier.rawValue
        manifest[.removeJailbreakEnabledKey] = removeJailbreakEnabled ? "true" : "false"
        return manifest
    }

    mutating func consumeRemoveJailbreakRequest() {
        guard removeJailbreakEnabled else { return }
        removeJailbreakEnabled = false
    }
}

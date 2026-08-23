import Foundation

/// Read-only jailbreak-state probe for the pre-jailbreak interface.
///
/// Deliberately does **not** reuse `RLXBootstrapRootScanner`: that scanner is
/// a preparation step and deletes incomplete roots as it walks them, which is
/// the last thing a view should be able to trigger. Only its naming rules are
/// mirrored here — `.jbroot-<16 hex>` whose low byte is an XOR checksum of the
/// upper seven — plus the `.installed_relaxin` completion marker. Everything
/// this type does is a directory listing and a `stat`.
enum JailbreakStateProbe {
    enum State: Equatable {
        /// Nothing installed and nothing running.
        case none
        /// A finished bootstrap is on disk but the runtime isn't live. This is
        /// what a reboot leaves behind: the jailbreak is installed, it just
        /// has to be re-applied before it does anything.
        case installedInactive
        /// The RootHide runtime is live in this process.
        case active
    }

    private static let primaryRootDirectory = "/var/containers/Bundle/Application"
    private static let rootPrefix = ".jbroot-"
    private static let installedMarker = ".installed_relaxin"

    static func state(isRuntimeActive: Bool) -> State {
        if isRuntimeActive { return .active }
        return hasInstalledBootstrap() ? .installedInactive : .none
    }

    /// Whether a *completed* jbroot exists on disk.
    ///
    /// An unreadable container directory is reported as "nothing installed"
    /// rather than as an install we cannot see — the pre-jailbreak app is
    /// unsandboxed, so failing to read it means something is off, and
    /// claiming an install would offer a removal that can't work.
    static func hasInstalledBootstrap() -> Bool {
        let manager = FileManager.default
        guard let names = try? manager.contentsOfDirectory(atPath: primaryRootDirectory) else {
            return false
        }
        return names.contains { name in
            guard isJailbreakRootName(name) else { return false }
            let root = (primaryRootDirectory as NSString)
                .appendingPathComponent(name)
            let marker = (root as NSString)
                .appendingPathComponent(installedMarker)
            return manager.fileExists(atPath: marker)
        }
    }

    /// `.jbroot-XXXXXXXXXXXXXXXX` where the low byte is an XOR checksum of the
    /// upper seven. Same rule as `-[RLXBootstrapRootScanner rootName:containsBrand:]`;
    /// it is what tells a jbroot apart from anything else named similarly.
    static func isJailbreakRootName(_ name: String) -> Bool {
        guard name.count == rootPrefix.count + 16, name.hasPrefix(rootPrefix) else {
            return false
        }
        let digits = name.dropFirst(rootPrefix.count)
        guard let brand = UInt64(digits, radix: 16) else { return false }

        var checksum: UInt8 = 0
        for shift in stride(from: 8, through: 56, by: 8) {
            checksum ^= UInt8(truncatingIfNeeded: brand >> UInt64(shift))
        }
        return checksum == UInt8(truncatingIfNeeded: brand)
    }
}

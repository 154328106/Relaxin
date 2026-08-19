import Darwin
import Foundation
import UIKit

enum DeviceInfo {
    private static let timebaseInfo: mach_timebase_info_data_t? = {
        var info = mach_timebase_info_data_t()
        guard mach_timebase_info(&info) == KERN_SUCCESS, info.denom != 0 else {
            return nil
        }
        return info
    }()

    static let osVersion: String =
        sysctlString(named: "kern.osproductversion") ?? UIDevice.current.systemVersion

    static let osBuild: String? = sysctlString(named: "kern.osversion")

    static let cpuFamily: UInt32? = {
        var value: UInt32 = 0
        var size = MemoryLayout.size(ofValue: value)
        guard sysctlbyname("hw.cpufamily", &value, &size, nil, 0) == 0,
              size == MemoryLayout.size(ofValue: value)
        else {
            return nil
        }
        return value
    }()

    static let os: String = "\(UIDevice.current.systemName) \(osVersion)"

    static let modelIdentifier: String = {
        // Simulator's uname reports the Mac's arch; the env carries the model.
        if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModel
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        return string(from: systemInfo.machine)
    }()

    static let host = modelIdentifier

    static let kernel: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        return "\(string(from: systemInfo.sysname)) \(string(from: systemInfo.release))"
    }()

    static var uptime: String {
        var seconds = Int(elapsedTimeSinceBoot)
        let days = seconds / 86400
        seconds %= 86400
        let hours = seconds / 3600
        seconds %= 3600
        let minutes = seconds / 60
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Uptime rendered as "0天 12时 50分 05秒", suitable for the Chinese
    /// header on the home page.
    static var uptimeChinese: String {
        var seconds = Int(elapsedTimeSinceBoot)
        let days = seconds / 86400
        seconds %= 86400
        let hours = seconds / 3600
        seconds %= 3600
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d天 %02d时 %02d分 %02d秒", days, hours, minutes, secs)
    }

    static var uptimeSeconds: TimeInterval { elapsedTimeSinceBoot }

    /// Marketing name for the current model identifier, shortened for the
    /// home-screen info card ("iPhone15,3" → "14PM"). Falls back to the raw
    /// identifier when unknown.
    static var shortModelName: String {
        modelShortNameMap[modelIdentifier] ?? modelIdentifier
    }

    private static let modelShortNameMap: [String: String] = [
        // A12 (iPhone XS / XR)
        "iPhone11,2": "XS", "iPhone11,4": "XS Max", "iPhone11,6": "XS Max",
        "iPhone11,8": "XR",
        // A13 (iPhone 11 series)
        "iPhone12,1": "11", "iPhone12,3": "11 Pro", "iPhone12,5": "11 PM",
        "iPhone12,8": "SE 2",
        // A14 (iPhone 12 series)
        "iPhone13,1": "12 mini", "iPhone13,2": "12", "iPhone13,3": "12 Pro",
        "iPhone13,4": "12 PM",
        // A15 (iPhone 13 / 14 non-Pro)
        "iPhone14,4": "13 mini", "iPhone14,5": "13", "iPhone14,2": "13 Pro",
        "iPhone14,3": "13 PM", "iPhone14,6": "SE 3",
        "iPhone14,7": "14", "iPhone14,8": "14 Plus",
        // A16 (iPhone 14 Pro / 15)
        "iPhone15,2": "14 Pro", "iPhone15,3": "14 PM",
        "iPhone15,4": "15", "iPhone15,5": "15 Plus",
        // A17 Pro (iPhone 15 Pro)
        "iPhone16,1": "15 Pro", "iPhone16,2": "15 PM",
    ]

    private static var elapsedTimeSinceBoot: TimeInterval {
        guard let timebaseInfo else {
            return ProcessInfo.processInfo.systemUptime
        }
        // systemUptime pauses while the device sleeps; the continuous clock
        // measures the wall time users expect to have elapsed since boot.
        let nanoseconds = Double(mach_continuous_time())
            * Double(timebaseInfo.numer)
            / Double(timebaseInfo.denom)
        return nanoseconds / 1_000_000_000
    }

    private static func sysctlString(named name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else {
            return nil
        }

        var bytes = [UInt8](repeating: 0, count: size)
        let status = bytes.withUnsafeMutableBytes { buffer in
            sysctlbyname(name, buffer.baseAddress, &size, nil, 0)
        }
        guard status == 0 else { return nil }
        return String(decoding: bytes.prefix(while: { $0 != 0 }), as: UTF8.self)
    }

    private static func string(from tuple: some Any) -> String {
        withUnsafeBytes(of: tuple) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
    }
}

import Foundation

enum RelaxinChangelog {
    static let lines = [
        "Relaxin 0.5.3",
        "1、扩展了对 iOS 和 iPadOS 16.5 的支持",
        "2、提升了越狱在受支持设备和系统版本上的可靠性与兼容性",
        "3、修复了在内存压力较大时越狱功能失效的问题",
        "4、改善了在受支持系统版本中请求提升权限的进程的兼容性",
        "5、优化了越狱后侧载版 Relaxin 中的特权操作",
        "6、改进了在非默认系统应用可见时的越狱移除功能",
    ]

    static let characterCount = lines.reduce(0) { $0 + $1.count }

    static func terminalLines(visibleCharacterCount: Int) -> [String] {
        var remaining = min(max(0, visibleCharacterCount), characterCount)
        var output: [String] = []
        for (index, line) in lines.enumerated() {
            guard remaining > 0 else { break }
            let count = min(remaining, line.count)
            let visible = String(line.prefix(count))
            output.append(index == 0 ? TerminalStyle.bold(visible) : TerminalStyle.accent(visible))
            remaining -= count
            if index == 0, remaining > 0 {
                output.append("")
            }
        }
        return output
    }
}

import Foundation

enum RelaxinChangelog {
    static let lines = [
        "Relaxin 0.5.5",
        "1、新增主屏幕快捷操作，可直接启动越狱",
        "2、新增自动运行选项，启动应用后 30 秒自动开始越狱",
        "3、修复音量键导航问题",
        "4、改进与通过 TrollStore Lite 安装的应用的兼容性",
        "5、为 iOS 和 iPadOS 26 上兼容的 Frida 构建版本新增内存访问接口",
        "6、修复 iOS 和 iPadOS 18.4 及更高版本中，移除越狱后通过 IPA 安装的应用图标残留问题",
        "7、修复 iOS 和 iPadOS 17 及更高版本在用户空间重启后无法进行 Xcode 调试的问题",
        "8、提升 iOS 和 iPadOS 16 隐藏越狱痕迹时的稳定性",
        "9、内置 Irisin 软件包管理器更新至 4.5.21",
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

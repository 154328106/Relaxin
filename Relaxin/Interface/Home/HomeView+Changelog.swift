import Foundation

enum RelaxinChangelog {
    static let lines = [
        "Relaxin 0.5.4",
        "1、将内置的 RootHide Manager 替换为 Umbra 2.0",
        "2、新增 Irisin 4.4.1 作为可选的软件包管理器，首次设置时可选择，越狱后重新安装时也可选择",
        "3、新增自定义 URL Scheme 替换功能，同时继续对排除的 App 隐藏仅限越狱环境使用的链接",
        "4、在 iOS 和 iPadOS 16 上进一步隐藏越狱痕迹，避免被排除的 App 检测到",
        "5、提升 A12 设备的越狱成功率",
        "6、修复部分基于 PPL 的设备越狱失败问题",
        "7、修复部分设备上 Sileo 图标无法显示的问题",
        "8、改进 iOS 和 iPadOS 17 及更高版本中系统进程和辅助进程的崩溃报告收集",
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

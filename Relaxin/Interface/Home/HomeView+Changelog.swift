import Foundation

enum RelaxinChangelog {
    static let lines = [
        "Relaxin 0.5.1",
        "1、将 A12 和 A13 设备的支持范围扩展至 iOS 和 iPadOS 17.4–18.7.1 以及 26.0–26.0.1",
        "2、提升了所有受支持设备的越狱可靠性及内核内存访问能力",
        "3、改善了 iOS 和 iPadOS 17.4 及更高版本上应用与插件的启动兼容性",
        "4、提升了使用 Frida 时的兼容性与稳定性",
        "5、改善了 RootHide 对黑名单应用的隔离效果",
        "6、修复了非默认系统应用在用户空间重启后不显示，以及在移除越狱后仍然可见的问题",
        "7、修复了部分应用获取到错误“开发者模式”状态的问题",
        "8、改善了各系统版本间的信任缓存更新与恢复机制",
        "9、改善了在缺少匹配的 OTA（空中下载）文件时的内核缓存下载体验",
        "10、新增繁体中文、韩语、意大利语和葡萄牙语翻译",
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

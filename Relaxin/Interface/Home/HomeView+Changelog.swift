import Foundation

enum RelaxinChangelog {
    static let lines = [
        "Relaxin 0.5.6",
        "1、新增 A10/A10X 设备支持，兼容 iOS 和 iPadOS 16.5 到 18.7.1、A11 设备 16.5 到 16.7.16",
        "2、修复 iOS 和 iPadOS 17.4 及更高版本新越狱后包管理器图标无法显示的问题",
        "3、修复用户空间重启后部分第三方显示屏触摸无响应的问题",
        "4、修复现有越狱安装损坏时越狱卸载失败的问题",
        "5、修复启用越狱隐藏时通过注册文件类型向应用暴露越狱痕迹的问题",
        "6、通过隔离映射边界，提升内存访问失败时的稳定性",
        "7、新增可配置的自动运行计时器、包管理器选择和移动密码",
        "8、为 visionOS 和 tvOS 兼容性添加初步基础，目前这两个平台尚未官方支持",
        "9、提升越狱失败日志的可读性",
        "10、修复越狱和用户空间重启期间过度生成日志的问题",
        "11、内置 Irisin 软件包管理器更新至 4.7.2、Umbra 更新至 2.1",
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

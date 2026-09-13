import Foundation

enum RelaxinChangelog {
    static let lines = [
        "Relaxin 0.5.2",
        "1、改进了 RootHide 隔离机制，并对被排除的应用隐藏了更多越狱痕迹",
        "2、修复了在禁用插件注入时核心越狱功能不可用的问题",
        "3、改进了针对 TrollStore 安装方式的越狱移除流程，包括应用清理以及最终的系统界面重启",
        "4、修复了应用在创建子进程时偶发的系统卡死或看门狗（watchdog）重启问题",
        "5、改进了在 SPTM 设备上对被标记为已调试应用的 JIT 处理",
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

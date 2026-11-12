//
//  FileSizeFormatter.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

import Foundation

/// 字节数 → 人类可读字符串（"1.2 MB"）。
public enum FileSizeFormatter {
    /// 进制口径。
    public enum Style: Sendable {
        /// 1000 进制：Finder / 系统「关于本机」用的就是它。
        case file
        /// 1024 进制：内存、缓存这类按 2 的幂算的场景。
        case memory
    }

    /// 格式化字节数。
    ///
    /// 草案是手写单位表 + `String(format: "%.1f")`，有两个问题：
    /// 1. `String(format:)` 走 C locale，法语/德语下小数点是逗号，和系统其它位置对不上；
    /// 2. 单位进位、本地化、`.file`(1000) 与 `.memory`(1024) 的差异，系统已经处理好了。
    ///
    /// 所以这里只做一层薄封装，不再自己算单位。
    ///
    /// - Parameters:
    ///   - bytes: 负数按原样格式化（表示「待同步 / 差值」时有用），不做绝对值。
    ///   - locale: 显式传入以便测试固定语言；默认 `Locale.current`。
    /// - Note: 用 `ByteCountFormatStyle` 而不是 `ByteCountFormatter`：后者没有 `locale` 属性
    ///   （只能读当前 locale），测试就没法钉住输出。这个 format style 要求
    ///   macOS 12 / iOS 15 / watchOS 8，正好贴着本包最低版本。
    /// - Note: `spellsOutZero: false`。默认值会把 0 写成 "Zero kB" / "Zéro ko"，
    ///   空文件显示成一句话很怪；关掉后是 "0 bytes"。
    /// - Note: 小体积的进位是系统行为：1500 字节在 `.file` 下显示 "2 kB"（不是 "1.5 kB"），
    ///   1.5 MB 才带小数。这不是本工具算错，别为了「看起来精确」又手写一套单位表。
    public static func string(_ bytes: Int64, style: Style = .file, locale: Locale = .current) -> String {
        let format = ByteCountFormatStyle(style: style == .file ? .file : .memory, spellsOutZero: false)
        return bytes.formatted(format.locale(locale))
    }
}

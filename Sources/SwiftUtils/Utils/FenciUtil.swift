//
//  FenciUtil.swift
//
//
//  Created by zzh on 2024/9/21.
//
import Foundation
import NaturalLanguage

public class FenciUtil {
    private var tokenizer: NLTokenizer
    public init(_ fenciUnit: NLTokenUnit = .word) {
        self.tokenizer = NLTokenizer(unit: fenciUnit)
    }

    /// 选项：过滤标点、统一小写、最小长度等。
    public struct TokenOptions {
        public var lowercase: Bool = false // 是否将 token 转为小写
        public var omitPunctuation: Bool = true // 是否排除只包含标点的 token
        public var trimWhitespace: Bool = true // 是否去除 token 前后空白
        public var minLength: Int = 1 // 最小长度过滤（例如去掉单字符）
        public init(lowercase: Bool = false,
                    omitPunctuation: Bool = true,
                    trimWhitespace: Bool = true,
                    minLength: Int = 1)
        {
            self.lowercase = lowercase
            self.omitPunctuation = omitPunctuation
            self.trimWhitespace = trimWhitespace
            self.minLength = minLength
        }
    }

    // MARK: - 核心通用分词方法（推荐使用）

    /// 对文本进行分词并返回 token 字符串数组。
    /// - Parameters:
    ///   - text: 待分词文本
    ///   - unit: NLTokenUnit (.word / .sentence / .paragraph / .document)
    ///   - options: 过滤与归一化选项
    /// - Returns: token 字符串数组（已按文本顺序）
    public func fenci(
        _ text: String,
        unit: NLTokenUnit = .word,
        options: TokenOptions = .init()
    ) -> [String] {
        guard !text.isEmpty else { return [] }

        // [UPDATED] 使用局部 tokenizer 保证并发安全
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = text

        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { tokenRange, _ in
            var token = String(text[tokenRange])

            if options.trimWhitespace {
                token = token.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if options.lowercase {
                token = token.lowercased()
            }
            // 过滤：标点（如果用户要求）
            if options.omitPunctuation {
                // 如果 token 仅由标点/符号/空白组成，则跳过
                let trimmed = token.trimmingCharacters(in: .punctuationCharacters.union(.symbols).union(.whitespacesAndNewlines))
                if trimmed.isEmpty { return true } // continue
            }
            if token.count < max(0, options.minLength) {
                return true
            }

            tokens.append(token)
            return true
        }
        return tokens
    }

    // MARK: - 旧版分词方法（不推荐使用）

    public func fenciOld(_ text: String) -> [String] {
        if text.isEmpty {
            return []
        }
        self.tokenizer.string = text
        var tokens: [String] = []
        self.tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            tokens.append(token)
            return true
        }
        return tokens
    }

    // 单词
    public func fenciByWord(_ text: String) -> [String] {
        return self.fenci(text, unit: .word, options: .init())
    }

    // 句子
    public func fenciBySentence(_ text: String) -> [String] {
        return self.fenci(text, unit: .sentence, options: .init())
    }

    // 段落
    public func fenciByParagraph(_ text: String) -> [String] {
        return self.fenci(text, unit: .paragraph, options: .init())
    }

    // 文档
    public func fenciByDocument(_ text: String) -> [String] {
        return self.fenci(text, unit: .document, options: .init())
    }

    // MARK: - 返回 tokens + 在原文中的 Range（便于高亮或定位）

    /// 返回元组 (token, Range<String.Index>) 的数组
    public func fenciWithRanges(
        _ text: String,
        unit: NLTokenUnit = .word,
        options: TokenOptions = .init()
    ) -> [(String, Range<String.Index>)] {
        guard !text.isEmpty else { return [] }

        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = text

        var results: [(String, Range<String.Index>)] = []
        tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { tokenRange, _ in
            var token = String(text[tokenRange])

            if options.trimWhitespace {
                token = token.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if options.lowercase {
                token = token.lowercased()
            }
            if options.omitPunctuation {
                let trimmed = token.trimmingCharacters(in: .punctuationCharacters.union(.symbols).union(.whitespacesAndNewlines))
                if trimmed.isEmpty { return true }
            }
            if token.count < max(0, options.minLength) {
                return true
            }

            results.append((token, tokenRange))
            return true
        }
        return results
    }

    // MARK: - 小工具：把 tokens 通过空格连接成字符串（方便测试/调试）

    public static func joinTokens(_ tokens: [String], separator: String = " ") -> String {
        tokens.joined(separator: separator)
    }
}

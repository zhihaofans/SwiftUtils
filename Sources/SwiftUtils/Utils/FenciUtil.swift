//
//  FenciUtil.swift
//
//
//  Created by zzh on 2024/9/21.
//
import Foundation
import NaturalLanguage

public class FenciUtil {
    private let tokenizer: NLTokenizer
    public init(_ fenciUnit: NLTokenUnit = .word) {
        self.tokenizer = NLTokenizer(unit: fenciUnit)
    }

    public func fenci(_ text: String) -> [String] {
        if text.isEmpty {
            return []
        }
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            tokens.append(token)
            return true
        }
        return tokens
    }
    // 单词
    public func fenciByWord() -> [String] {
      self.tokenizer = NLTokenizer(unit: .word)
      return self.fenci(text)
    }
    // 句子
    public func fenciBySentence() -> [String] {
      self.tokenizer = NLTokenizer(unit: .sentence)
      return self.fenci(text)
    }
    // 段落
    public func fenciByParagraph() -> [String] {
      self.tokenizer = NLTokenizer(unit: .paragraph)
      return self.fenci(text)
    }
    // 文档
    public func fenciByDocument() -> [String] {
      self.tokenizer = NLTokenizer(unit: .document)
      return self.fenci(text)
    }
}

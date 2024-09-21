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
}

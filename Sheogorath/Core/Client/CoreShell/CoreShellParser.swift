//
//  CoreShellParser.swift
//  Sheogorath
//
//  Created by SITIS on 10/8/26.
//

import Foundation

struct CoreShellParser {
    enum Token: Equatable {
        case word(String)
        case pipe
        case overwrite
        case append
    }

    enum ParseError: LocalizedError {
        case unterminatedQuote

        var errorDescription: String? {
            "unterminated quote"
        }
    }

    static func parse(_ input: String) throws -> [Token] {
        enum Quote { case single, double }
        var tokens: [Token] = []
        var current = ""
        var quote: Quote?
        var hasContent = false

        func flush() {
            if hasContent {
                tokens.append(.word(current))
                current = ""
                hasContent = false
            }
        }

        let characters = Array(input)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            switch character {
            case "'":
                if quote == .double { current.append(character); hasContent = true }
                else if quote == .single { quote = nil }
                else { quote = .single; hasContent = true }
            case "\"":
                if quote == .single { current.append(character); hasContent = true }
                else if quote == .double { quote = nil }
                else { quote = .double; hasContent = true }
            case " ", "\t", "\n", "\r":
                if quote == nil { flush() }
                else { current.append(character); hasContent = true }
            case "|", ">":
                if quote == nil {
                    flush()
                    if character == "|" { tokens.append(.pipe) }
                    else if index + 1 < characters.count && characters[index + 1] == ">" {
                        tokens.append(.append)
                        index += 1
                    } else { tokens.append(.overwrite) }
                } else { current.append(character); hasContent = true }
            default:
                current.append(character)
                hasContent = true
            }
            index += 1
        }
        guard quote == nil else { throw ParseError.unterminatedQuote }
        flush()
        return tokens
    }
}

//
//  CoreShell.swift
//  Sheogorath
//
//  Created by SITIS on 9/28/26.
//

import Foundation

@MainActor
final class CoreShell {
    let core: SheoCore
    var currentDirectory: URL

    init(core: SheoCore, currentDirectory: URL? = nil) {
        self.core = core
        self.currentDirectory = (currentDirectory ?? Bundle.main.resourceURL!).standardizedFileURL
    }

    func execute(_ input: String) async -> String {
        let tokens: [CoreShellParser.Token]
        do {
            tokens = try CoreShellParser.parse(input)
        } catch {
            return "parse error: \(error.localizedDescription)"
        }

        guard !tokens.isEmpty else { return "" }

        var stages: [[String]] = [[]]
        var redirect: (path: String, append: Bool)?
        var index = 0

        while index < tokens.count {
            switch tokens[index] {
            case .word(let word):
                guard redirect == nil else { return "parse error: unexpected argument after redirect" }
                stages[stages.count - 1].append(word)
            case .pipe:
                guard redirect == nil, !stages[stages.count - 1].isEmpty else {
                    return "parse error: invalid pipeline"
                }
                stages.append([])
            case .overwrite, .append:
                guard redirect == nil, !stages[stages.count - 1].isEmpty,
                      index + 1 < tokens.count,
                      case .word(let path) = tokens[index + 1] else {
                    return "parse error: invalid redirect"
                }
                redirect = (path, tokens[index] == .append)
                index += 1
            }
            index += 1
        }

        guard !stages[stages.count - 1].isEmpty else { return "parse error: invalid pipeline" }

        var output = ""
        for (stageIndex, arguments) in stages.enumerated() {
            let result = await runCommand(arguments, input: stageIndex == 0 ? nil : output)
            guard result.success else { return result.text }
            output = result.text
        }

        guard let redirect else { return output }
        let url = resolvedURL(for: redirect.path)
        guard core.canAccess(url) else { return "permission denied: \(url.path)" }
        do {
            let data = Data((output + "\n").utf8)
            if redirect.append, FileManager.default.fileExists(atPath: url.path) {
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } else {
                try data.write(to: url, options: .atomic)
            }
            return ""
        } catch {
            return "redirect: \(error.localizedDescription)"
        }
    }

    private func runCommand(_ arguments: [String], input: String?) async -> (text: String, success: Bool) {
        guard let command = arguments.first else { return ("", false) }
        let operands = Array(arguments.dropFirst())
        if input != nil && command != "cat" && command != "grep" && command != "tee" {
            return ("pipeline: command does not accept input: \(command)", false)
        }
        switch command {
        case "curl": return await curl(arguments: operands)
        case "pwd": return (currentDirectory.path, true)
        case "open": return openPath(arguments: operands)
        case "ls": return listDirectory(arguments: operands)
        case "tree": return treeDirectory(arguments: operands)
        case "cd": return changeDirectory(arguments: operands)
        case "mkdir": return makeDirectory(arguments: operands)
        case "touch": return touch(arguments: operands)
        case "cp": return copy(arguments: operands)
        case "mv": return move(arguments: operands)
        case "rm": return remove(arguments: operands)
        case "echo": return (echo(arguments: operands), true)
        case "cat":
            if let input {
                return operands.isEmpty ? (input, true) : ("usage: cat [file]", false)
            }
            return cat(arguments: operands)
        case "grep": return grep(arguments: operands, input: input)
        case "tee": return tee(arguments: operands, input: input)
        default: return ("command not found: \(command)", false)
        }
    }
}

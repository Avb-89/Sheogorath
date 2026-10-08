//
//  CoreShellCommands.swift
//  Sheogorath
//
//  Created by SITIS on 10/8/26.
//

import Foundation
import AppKit

@MainActor
extension CoreShell {
    func resolvedURL(for path: String) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path).standardizedFileURL
        }
        return currentDirectory.appendingPathComponent(path).standardizedFileURL
    }

    func listDirectory(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count <= 1 else { return ("usage: ls [path]", false) }
        let url = arguments.first.map(resolvedURL(for:)) ?? currentDirectory
        do {
            _ = try core.readProtected(url)
            let items = try FileManager.default.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            )
            return (items.map(\.lastPathComponent).sorted().joined(separator: "\n"), true)
        } catch { return ("ls: \(error.localizedDescription)", false) }
    }

    func treeDirectory(arguments: [String]) -> (text: String, success: Bool) {
        var path: String?
        var maximumDepth: Int?
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument == "-L" {
                guard maximumDepth == nil,
                      index + 1 < arguments.count,
                      let depth = Int(arguments[index + 1]),
                      (1...9).contains(depth) else {
                    return ("usage: tree [-L 1-9] [path]", false)
                }
                maximumDepth = depth
                index += 2
                continue
            }
            guard path == nil else { return ("usage: tree [-L 1-9] [path]", false) }
            path = argument
            index += 1
        }
        let root = path.map(resolvedURL(for:)) ?? currentDirectory
        guard core.canAccess(root) else { return ("[access denied]", false) }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return ("tree: not a directory: \(path ?? root.path)", false)
        }
        let rootLabel = path == nil ? "." : (root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent)
        var lines = [rootLabel]
        appendTree(at: root, prefix: "", depth: 0, maximumDepth: maximumDepth, lines: &lines)
        return (lines.joined(separator: "\n"), true)
    }

    func appendTree(
        at directory: URL, prefix: String, depth: Int, maximumDepth: Int?, lines: inout [String]
    ) {
        if let maximumDepth, depth >= maximumDepth { return }
        let children: [URL]
        do {
            children = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                options: []
            ).sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
        } catch {
            lines.append("\(prefix)└── [access denied]")
            return
        }
        for (index, child) in children.enumerated() {
            let isLast = index == children.count - 1
            let branch = isLast ? "└── " : "├── "
            guard core.canAccess(child) else {
                lines.append("\(prefix)\(branch)[access denied]")
                continue
            }
            lines.append("\(prefix)\(branch)\(child.lastPathComponent)")
            let values: URLResourceValues
            do { values = try child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]) }
            catch { continue }
            guard values.isDirectory == true, values.isSymbolicLink != true else { continue }
            appendTree(
                at: child,
                prefix: prefix + (isLast ? "    " : "│   "),
                depth: depth + 1, maximumDepth: maximumDepth, lines: &lines
            )
        }
    }

    func changeDirectory(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 1 else { return ("usage: cd <path>", false) }
        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else { return ("permission denied: \(url.path)", false) }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return ("cd: not a directory: \(arguments[0])", false)
        }
        currentDirectory = url
        return ("", true)
    }

    func makeDirectory(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 1 else { return ("usage: mkdir <path>", false) }
        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else { return ("permission denied: \(url.path)", false) }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            return ("", true)
        } catch { return ("mkdir: \(error.localizedDescription)", false) }
    }

    func touch(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 1 else { return ("usage: touch <path>", false) }
        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else { return ("permission denied: \(url.path)", false) }
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
                return ("", true)
            } catch { return ("touch: \(error.localizedDescription)", false) }
        }
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            return ("touch: failed to create file: \(arguments[0])", false)
        }
        return ("", true)
    }

    func copy(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 2 else { return ("usage: cp <source> <destination>", false) }
        let source = resolvedURL(for: arguments[0])
        let destination = resolvedURL(for: arguments[1])
        guard core.canAccess(source), core.canAccess(destination) else {
            return ("permission denied", false)
        }
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return ("", true)
        } catch { return ("cp: \(error.localizedDescription)", false) }
    }

    func move(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 2 else { return ("usage: mv <source> <destination>", false) }
        let source = resolvedURL(for: arguments[0])
        let destination = resolvedURL(for: arguments[1])
        guard core.canAccess(source), core.canAccess(destination) else {
            return ("permission denied", false)
        }
        do {
            try FileManager.default.moveItem(at: source, to: destination)
            return ("", true)
        } catch { return ("mv: \(error.localizedDescription)", false) }
    }

    func remove(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 1 else { return ("usage: rm <path>", false) }
        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else { return ("permission denied: \(url.path)", false) }
        do {
            try FileManager.default.removeItem(at: url)
            return ("", true)
        } catch { return ("rm: \(error.localizedDescription)", false) }
    }

    func echo(arguments: [String]) -> String { arguments.joined(separator: " ") }

    func cat(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 1 else { return ("usage: cat <file>", false) }
        let url = resolvedURL(for: arguments[0])
        do {
            let data = try core.readProtected(url)
            guard let text = String(data: data, encoding: .utf8) else {
                return ("cat: file is not valid UTF-8: \(arguments[0])", false)
            }
            return (text, true)
        } catch { return ("cat: \(error.localizedDescription)", false) }
    }

    func grep(arguments: [String], input: String? = nil) -> (text: String, success: Bool) {
        var ignoreCase = false
        var showLineNumbers = false
        var operands: [String] = []
        for argument in arguments {
            if operands.isEmpty && argument.hasPrefix("-") && argument != "-" {
                let flags = argument.dropFirst()
                guard !flags.isEmpty, flags.allSatisfy({ $0 == "i" || $0 == "n" }) else {
                    return ("usage: grep [-i] [-n] <pattern> <file>", false)
                }
                ignoreCase = ignoreCase || flags.contains("i")
                showLineNumbers = showLineNumbers || flags.contains("n")
            } else { operands.append(argument) }
        }
        guard operands.count == (input == nil ? 2 : 1) else {
            return (input == nil ? "usage: grep [-i] [-n] <pattern> <file>" :
                "usage: grep [-i] [-n] <pattern>", false)
        }
        let content: String
        if let input { content = input }
        else {
            let url = resolvedURL(for: operands[1])
            do {
                let data = try core.readProtected(url)
                guard let decoded = String(data: data, encoding: .utf8) else {
                    return ("grep: file is not valid UTF-8: \(operands[1])", false)
                }
                content = decoded
            } catch { return ("grep: \(error.localizedDescription)", false) }
        }
        let result = content.components(separatedBy: .newlines).enumerated().compactMap { index, line in
            let matches = ignoreCase
                ? line.range(of: operands[0], options: [.caseInsensitive]) != nil
                : line.contains(operands[0])
            guard matches else { return nil }
            return showLineNumbers ? "\(index + 1):\(line)" : line
        }.joined(separator: "\n")
        return (result, true)
    }

    func tee(arguments: [String], input: String?) -> (text: String, success: Bool) {
        guard arguments.count == 1 else { return ("usage: tee <file>", false) }
        guard let input else { return ("tee: input required (use a pipeline)", false) }
        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else { return ("permission denied: \(url.path)", false) }
        do {
            try Data((input + "\n").utf8).write(to: url, options: .atomic)
            return (input, true)
        } catch { return ("tee: \(error.localizedDescription)", false) }
    }

    func openPath(arguments: [String]) -> (text: String, success: Bool) {
        guard arguments.count == 1 else { return ("usage: open <path>", false) }
        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else { return ("permission denied: \(url.path)", false) }
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ("open: no such file or directory: \(url.path)", false)
        }
        guard NSWorkspace.shared.open(url) else {
            return ("open: failed to open: \(url.path)", false)
        }
        return ("", true)
    }
}

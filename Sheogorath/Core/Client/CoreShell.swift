//
//  CoreShell.swift
//  Sheogorath
//
//  Created by SITIS on 9/28/26.
//

import Foundation

@MainActor
final class CoreShell {
    private let core: SheoCore
    private var currentDirectory: URL

    init(core: SheoCore, currentDirectory: URL? = nil) {
        self.core = core
        self.currentDirectory = (currentDirectory ?? Bundle.main.resourceURL!).standardizedFileURL
    }

    func execute(_ input: String) -> String {
        let arguments = input.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let command = arguments.first else { return "" }

        switch command {
        case "pwd":
            return currentDirectory.path
        case "ls":
            return listDirectory(arguments: Array(arguments.dropFirst()))
        case "tree":
            return treeDirectory(arguments: Array(arguments.dropFirst()))
        case "cd":
            return changeDirectory(arguments: Array(arguments.dropFirst()))
        case "mkdir":
            return makeDirectory(arguments: Array(arguments.dropFirst()))
        case "touch":
            return touch(arguments: Array(arguments.dropFirst()))
        case "cp":
            return copy(arguments: Array(arguments.dropFirst()))
        case "mv":
            return move(arguments: Array(arguments.dropFirst()))
        case "rm":
            return remove(arguments: Array(arguments.dropFirst()))
        default:
            return "command not found: \(command)"
        }
    }

    private func resolvedURL(for path: String) -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path).standardizedFileURL
        }

        return currentDirectory
            .appendingPathComponent(path)
            .standardizedFileURL
    }

    private func listDirectory(arguments: [String]) -> String {
        guard arguments.count <= 1 else {
            return "usage: ls [path]"
        }

        let url = arguments.first.map(resolvedURL(for:)) ?? currentDirectory

        do {
            _ = try core.readProtected(url)
            let items = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return items.map(\.lastPathComponent).sorted().joined(separator: "\n")
        } catch {
            return "ls: \(error.localizedDescription)"
        }
    }

    private func treeDirectory(arguments: [String]) -> String {
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
                    return "usage: tree [-L 1-9] [path]"
                }

                maximumDepth = depth
                index += 2
                continue
            }

            guard path == nil else {
                return "usage: tree [-L 1-9] [path]"
            }

            path = argument
            index += 1
        }

        let root = path.map(resolvedURL(for:)) ?? currentDirectory
        guard core.canAccess(root) else {
            return "[access denied]"
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return "tree: not a directory: \(path ?? root.path)"
        }

        var lines = [root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent]
        appendTree(
            at: root,
            prefix: "",
            depth: 0,
            maximumDepth: maximumDepth,
            lines: &lines
        )
        return lines.joined(separator: "\n")
    }

    private func appendTree(
        at directory: URL,
        prefix: String,
        depth: Int,
        maximumDepth: Int?,
        lines: inout [String]
    ) {
        if let maximumDepth, depth >= maximumDepth {
            return
        }

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
            do {
                values = try child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            } catch {
                continue
            }

            guard values.isDirectory == true, values.isSymbolicLink != true else {
                continue
            }

            appendTree(
                at: child,
                prefix: prefix + (isLast ? "    " : "│   "),
                depth: depth + 1,
                maximumDepth: maximumDepth,
                lines: &lines
            )
        }
    }

    private func changeDirectory(arguments: [String]) -> String {
        guard arguments.count == 1 else {
            return "usage: cd <path>"
        }

        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else {
            return "permission denied: \(url.path)"
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return "cd: not a directory: \(arguments[0])"
        }

        currentDirectory = url
        return ""
    }

    private func makeDirectory(arguments: [String]) -> String {
        guard arguments.count == 1 else {
            return "usage: mkdir <path>"
        }

        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else {
            return "permission denied: \(url.path)"
        }

        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: false
            )
            return ""
        } catch {
            return "mkdir: \(error.localizedDescription)"
        }
    }

    private func touch(arguments: [String]) -> String {
        guard arguments.count == 1 else {
            return "usage: touch <path>"
        }

        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else {
            return "permission denied: \(url.path)"
        }

        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.setAttributes(
                    [.modificationDate: Date()],
                    ofItemAtPath: url.path
                )
                return ""
            } catch {
                return "touch: \(error.localizedDescription)"
            }
        }

        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            return "touch: failed to create file: \(arguments[0])"
        }
        return ""
    }

    private func copy(arguments: [String]) -> String {
        guard arguments.count == 2 else {
            return "usage: cp <source> <destination>"
        }

        let source = resolvedURL(for: arguments[0])
        let destination = resolvedURL(for: arguments[1])
        guard core.canAccess(source), core.canAccess(destination) else {
            return "permission denied"
        }

        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return ""
        } catch {
            return "cp: \(error.localizedDescription)"
        }
    }

    private func move(arguments: [String]) -> String {
        guard arguments.count == 2 else {
            return "usage: mv <source> <destination>"
        }

        let source = resolvedURL(for: arguments[0])
        let destination = resolvedURL(for: arguments[1])
        guard core.canAccess(source), core.canAccess(destination) else {
            return "permission denied"
        }

        do {
            try FileManager.default.moveItem(at: source, to: destination)
            return ""
        } catch {
            return "mv: \(error.localizedDescription)"
        }
    }

    private func remove(arguments: [String]) -> String {
        guard arguments.count == 1 else {
            return "usage: rm <path>"
        }

        let url = resolvedURL(for: arguments[0])
        guard core.canAccess(url) else {
            return "permission denied: \(url.path)"
        }

        do {
            try FileManager.default.removeItem(at: url)
            return ""
        } catch {
            return "rm: \(error.localizedDescription)"
        }
    }
}

//
//  TerminalShell.swift
//  Sheogorath
//
//  Created by SITIS on 9/24/26.
//

import Foundation

struct TerminalShell {
    private var environment: TerminalEnv
    private let core: SheoCore

    init(core: SheoCore, environment: TerminalEnv = TerminalEnv()) {
        self.core = core
        self.environment = environment
    }

    mutating func execute(_ input: String) -> String {
        let arguments = input.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let command = arguments.first else { return "" }

        switch command {
        case "pwd":
            return environment.currentDirectory.path
        case "ls":
            return listDirectory(arguments: Array(arguments.dropFirst()))
        case "cd":
            return changeDirectory(arguments: Array(arguments.dropFirst()))
        default:
            return "command not found: \(command)"
        }
    }

    private func resolvedURL(for path: String?) -> URL {
        guard let path, !path.isEmpty else {
            return environment.currentDirectory
        }

        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path).standardizedFileURL
        }

        return environment.currentDirectory
            .appendingPathComponent(path)
            .standardizedFileURL
    }

    private func listDirectory(arguments: [String]) -> String {
        guard arguments.count <= 1 else {
            return "usage: ls [path]"
        }

        let url = resolvedURL(for: arguments.first)
        do {
            _ = try core.readProtected(url)

            let items = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: []
            )
            return items
                .map(\.lastPathComponent)
                .sorted()
                .joined(separator: "\n")
        } catch {
            return "ls: \(error.localizedDescription)"
        }
    }

    private mutating func changeDirectory(arguments: [String]) -> String {
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

        environment.changeDirectory(to: url)
        return ""
    }
}

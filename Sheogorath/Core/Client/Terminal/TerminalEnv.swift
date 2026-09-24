//
//  TerminalEnv.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct TerminalEnv: Sendable {
    private(set) var currentDirectory: URL

    init(currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) {
        self.currentDirectory = currentDirectory.standardizedFileURL
    }

    mutating func changeDirectory(to directory: URL) {
        currentDirectory = directory.standardizedFileURL
    }
}

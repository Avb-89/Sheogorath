//
//  CoreLog.swift
//  Sheogorath
//
//  Created by SITIS on 9/25/26.
//

import Foundation

enum CoreLog {
    static var directoryURL: URL {
        Bundle.main.resourceURL!
            .appendingPathComponent("Logs", isDirectory: true)
    }

    static var fileURL: URL {
        directoryURL.appendingPathComponent("core.log")
    }

    static func append(_ lines: [String]) throws {
        guard !lines.isEmpty else { return }

        let text = lines.joined(separator: "\n") + "\n"
        let data = Data(text.utf8)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            try data.write(to: fileURL, options: .atomic)
            return
        }

        let handle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? handle.close()
        }

        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }
}

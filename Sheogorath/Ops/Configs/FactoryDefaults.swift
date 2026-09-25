//
//  Config.swift
//  Sheogorath
//
//  Created by SITIS on 9/25/26.
//

import Foundation

enum Config {
    static let directoryName = "Configs"
    static let modeFileName = "mode.json"
    static let modulesFileName = "modules.json"

    static var directoryURL: URL {
        Bundle.main.resourceURL!
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    static var modeURL: URL {
        directoryURL.appendingPathComponent(modeFileName)
    }

    static var modulesURL: URL {
        directoryURL.appendingPathComponent(modulesFileName)
    }

    static func generate() throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        if !FileManager.default.fileExists(atPath: modeURL.path) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(CapabilityPolicy())
            try data.write(to: modeURL, options: .atomic)
        }

        if !FileManager.default.fileExists(atPath: modulesURL.path) {
            let data = try JSONSerialization.data(
                withJSONObject: ["modules": []],
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: modulesURL, options: .atomic)
        }
    }
}

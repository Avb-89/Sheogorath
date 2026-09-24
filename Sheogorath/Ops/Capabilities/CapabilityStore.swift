//
//  CapabilityStore.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct CapabilityStore: Sendable {
    private let fileURL: URL

    init() {
        fileURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Configs/mode.json")
    }

    init(fileURL: URL) {
        self.fileURL = fileURL.standardizedFileURL
    }

    func load() throws -> CapabilityPolicy {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(CapabilityPolicy.self, from: data)
    }

    func save(_ policy: CapabilityPolicy) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(policy)
        try data.write(to: fileURL, options: .atomic)
    }
}

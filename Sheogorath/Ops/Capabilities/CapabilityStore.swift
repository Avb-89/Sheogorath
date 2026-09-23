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
            .appendingPathComponent("Contents/configs/mode.json")
    }

    func load() -> CapabilityPolicy {
        guard let data = try? Data(contentsOf: fileURL),
              let policy = try? JSONDecoder().decode(CapabilityPolicy.self, from: data) else {
            return CapabilityPolicy()
        }

        return policy
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

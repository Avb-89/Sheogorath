//
//  CapabilityStore.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

final class CapabilityStore: @unchecked Sendable {
    private let fileURL: URL
    private var source: DispatchSourceFileSystemObject?
    private var directoryDescriptor: Int32 = -1

    init() {
        fileURL = Bundle.main.resourceURL!
            .appendingPathComponent("Configs/mode.json")
    }

    init(fileURL: URL) {
        self.fileURL = fileURL.standardizedFileURL
    }

    deinit {
        stopWatching()
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

    func watch(_ onChange: @escaping @Sendable () -> Void) throws {
        stopWatching()

        let directoryURL = fileURL.deletingLastPathComponent()
        let descriptor = open(directoryURL.path, O_EVTONLY)
        guard descriptor >= 0 else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        directoryDescriptor = descriptor

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.global(qos: .userInitiated)
        )

        source.setEventHandler {
            onChange()
        }

        source.setCancelHandler { [descriptor] in
            close(descriptor)
        }

        self.source = source
        source.resume()
    }

    func stopWatching() {
        source?.cancel()
        source = nil
        directoryDescriptor = -1
    }
}

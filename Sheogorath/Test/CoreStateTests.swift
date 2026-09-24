//
//  CoreStateTests.swift
//  Sheogorath
//
//  Created by SITIS on 9/24/26.
//

import Foundation

#if DEBUG
@MainActor
enum CoreStateTests {
    static func run() -> [String] {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("Sheogorath-CoreStateTests-\(UUID().uuidString)", isDirectory: true)
        let validModeFile = root.appendingPathComponent("valid-mode.json")
        let missingModeFile = root.appendingPathComponent("missing-mode.json")
        let brokenModeFile = root.appendingPathComponent("broken-mode.json")

        do {
            try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
            try CapabilityStore(fileURL: validModeFile).save(CapabilityPolicy())
            try Data("not valid json".utf8).write(to: brokenModeFile)
        } catch {
            return ["[FAIL] Core State test setup: \(error.localizedDescription)"]
        }

        defer {
            try? fileManager.removeItem(at: root)
        }

        var results: [String] = []

        let readyCore = SheoCore(capabilityStore: CapabilityStore(fileURL: validModeFile))
        results.append(
            readyCore.state == .ready
                ? "[PASS] Core enters ready state with valid mode.json"
                : "[FAIL] Core enters ready state with valid mode.json"
        )

        let missingCore = SheoCore(capabilityStore: CapabilityStore(fileURL: missingModeFile))
        results.append(
            isOblivionMode(missingCore.state)
                ? "[PASS] Core enters Oblivion Mode when mode.json is missing"
                : "[FAIL] Core enters Oblivion Mode when mode.json is missing"
        )

        let brokenCore = SheoCore(capabilityStore: CapabilityStore(fileURL: brokenModeFile))
        results.append(
            isOblivionMode(brokenCore.state)
                ? "[PASS] Core enters Oblivion Mode when mode.json is invalid"
                : "[FAIL] Core enters Oblivion Mode when mode.json is invalid"
        )

        let probeURL = root.appendingPathComponent("probe")
        results.append(
            !brokenCore.canAccess(probeURL, from: .terminal)
                ? "[PASS] Oblivion Mode denies capability access"
                : "[FAIL] Oblivion Mode denies capability access"
        )

        return results
    }

    private static func isOblivionMode(_ state: SheoCore.State) -> Bool {
        if case .oblivionMode = state {
            return true
        }
        return false
    }
}
#endif

//
//  TerminalShellTests.swift
//  Sheogorath
//
//  Created by SITIS on 9/24/26.
//

import Foundation

#if DEBUG
enum TerminalShellTests {
    static func run() -> [String] {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("Sheogorath-TerminalShellTests-\(UUID().uuidString)", isDirectory: true)
        let allowed = root.appendingPathComponent("allowed", isDirectory: true)
        let child = allowed.appendingPathComponent("child", isDirectory: true)
        let denied = root.appendingPathComponent("denied", isDirectory: true)
        let visibleFile = allowed.appendingPathComponent("visible.txt")
        let modeFile = root.appendingPathComponent("mode.json")

        do {
            try fileManager.createDirectory(at: child, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: denied, withIntermediateDirectories: true)
            try Data().write(to: visibleFile)
            try CapabilityStore(fileURL: modeFile).save(CapabilityPolicy())
        } catch {
            return ["[FAIL] Terminal Shell test setup: \(error.localizedDescription)"]
        }

        defer {
            try? fileManager.removeItem(at: root)
        }

        let core = SheoCore(capabilityStore: CapabilityStore(fileURL: modeFile))

        do {
            try core.addAllowedPath(
                allowed.path,
                context: ClientContext(type: .terminal)
            )
        } catch {
            return ["[FAIL] Terminal Shell policy setup: \(error.localizedDescription)"]
        }

        var shell = TerminalShell(
            core: core,
            environment: TerminalEnv(currentDirectory: allowed)
        )

        var results: [String] = []

        results.append(
            shell.execute("pwd") == allowed.path
                ? "[PASS] Terminal pwd returns current directory"
                : "[FAIL] Terminal pwd returns current directory"
        )

        let listing = shell.execute("ls")
        results.append(
            listing.split(separator: "\n").map(String.init) == ["child", "visible.txt"]
                ? "[PASS] Terminal ls reads allowed directory"
                : "[FAIL] Terminal ls reads allowed directory"
        )

        let deniedListing = shell.execute("ls \(denied.path)")
        results.append(
            deniedListing == "permission denied: \(denied.path)"
                ? "[PASS] Terminal ls denies forbidden directory"
                : "[FAIL] Terminal ls denies forbidden directory"
        )

        let allowedChange = shell.execute("cd child")
        results.append(
            allowedChange.isEmpty && shell.execute("pwd") == child.path
                ? "[PASS] Terminal cd changes to allowed directory"
                : "[FAIL] Terminal cd changes to allowed directory"
        )

        let beforeDeniedChange = shell.execute("pwd")
        let deniedChange = shell.execute("cd \(denied.path)")
        let afterDeniedChange = shell.execute("pwd")
        results.append(
            deniedChange == "permission denied: \(denied.path)" && beforeDeniedChange == afterDeniedChange
                ? "[PASS] Terminal denied cd preserves current directory"
                : "[FAIL] Terminal denied cd preserves current directory"
        )

        return results
    }
}
#endif

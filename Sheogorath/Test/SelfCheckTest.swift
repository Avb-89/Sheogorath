//
//  SelfCheckTest.swift
//  Sheogorath
//
//  Created by SITIS on 9/25/26.
//

import Foundation

enum SelfCheckTest {
    enum Failure: Error {
        case failed(section: String, step: String, detail: String)
    }

    struct Result {
        let report: [String]
        let diagnostic: CoreDiagnostic
    }

    @MainActor
    static func run(core: SheoCore) -> Result {
        var output: [String] = []
        var failures: [CoreDiagnostic.Failure] = []
        var skipped: [CoreDiagnostic.Skipped] = []

        let clock = ContinuousClock()
        let startedAt = clock.now
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        output.append("[self-check] \(formatter.string(from: Date()))")
        output.append("")

        output.append("[initialize]")
        let resourcesURL = Bundle.main.resourceURL!

        for directory in ["Configs", "Manuals", "Modules", "Logs", "Registry"] {
            record(
                section: "initialize",
                step: "\(directory)/",
                clock: clock,
                startedAt: startedAt,
                output: &output,
                failures: &failures
            ) {
                try checkDirectory(
                    resourcesURL.appendingPathComponent(directory, isDirectory: true),
                    name: directory
                )
            }
        }

        record(
            section: "initialize",
            step: "mode.json",
            clock: clock,
            startedAt: startedAt,
            output: &output,
            failures: &failures,
            operation: checkModeFile
        )
        record(
            section: "initialize",
            step: "modules.json",
            clock: clock,
            startedAt: startedAt,
            output: &output,
            failures: &failures,
            operation: checkModulesFile
        )
        record(
            section: "initialize",
            step: "registry.db",
            clock: clock,
            startedAt: startedAt,
            output: &output,
            failures: &failures,
            operation: checkRegistryFile
        )

        output.append("")
        output.append("[permission]")

        let originalData: Data?
        let originalPolicy: CapabilityPolicy?

        if let data = try? Data(contentsOf: Config.modeURL),
           let policy = try? JSONDecoder().decode(CapabilityPolicy.self, from: data) {
            originalData = data
            originalPolicy = policy
        } else {
            originalData = nil
            originalPolicy = nil
        }

        if let originalData, let originalPolicy {
            record(
                section: "permission",
                step: "mode WABBAJACK",
                clock: clock,
                startedAt: startedAt,
                output: &output,
                failures: &failures
            ) {
                try withRestoredPolicy(core: core, originalData: originalData, originalPolicy: originalPolicy) {
                    try activate(.wabbajack, core: core)
                }
            }

            record(
                section: "permission",
                step: "mode PelagiusIII",
                clock: clock,
                startedAt: startedAt,
                output: &output,
                failures: &failures
            ) {
                try withRestoredPolicy(core: core, originalData: originalData, originalPolicy: originalPolicy) {
                    try activate(.pelagiusIII, core: core)
                }
            }

            record(
                section: "permission",
                step: "user permission WABBAJACK",
                clock: clock,
                startedAt: startedAt,
                output: &output,
                failures: &failures
            ) {
                try withRestoredPolicy(core: core, originalData: originalData, originalPolicy: originalPolicy) {
                    try activate(.wabbajack, core: core)
                    for path in originalPolicy.profile.wabbajackDeniedPaths {
                        try expectDenied(path: path, core: core, mode: "WABBAJACK")
                    }
                }
            }

            record(
                section: "permission",
                step: "user permission PelagiusIII",
                clock: clock,
                startedAt: startedAt,
                output: &output,
                failures: &failures
            ) {
                try withRestoredPolicy(core: core, originalData: originalData, originalPolicy: originalPolicy) {
                    try activate(.pelagiusIII, core: core)
                    for path in originalPolicy.profile.pelagiusIIIAllowedPaths {
                        try expectAllowed(path: path, core: core, mode: "PelagiusIII")
                    }
                }
            }

            record(
                section: "permission",
                step: "close test session",
                clock: clock,
                startedAt: startedAt,
                output: &output,
                failures: &failures
            ) {
                guard core.capabilityMode() == originalPolicy.profile.mode else {
                    throw Failure.failed(
                        section: "permission",
                        step: "close test session",
                        detail: "running Core did not return to original policy"
                    )
                }
            }
        } else {
            for step in [
                "mode WABBAJACK",
                "mode PelagiusIII",
                "user permission WABBAJACK",
                "user permission PelagiusIII",
                "close test session"
            ] {
                let item = CoreDiagnostic.Skipped(
                    section: "permission",
                    step: step,
                    detail: "dependency: mode.json unavailable"
                )
                skipped.append(item)
                output.append("step - \(item.step) [skipped] \(item.detail)")
            }
        }

        output.append("")
        output.append("[result]")

        if failures.isEmpty {
            output.append("SUCCESS")
        } else {
            output.append("FAILED")
            output.append("\(failures.count) failure(s)")
            if !skipped.isEmpty {
                output.append("\(skipped.count) skipped")
            }
        }

        return Result(
            report: output,
            diagnostic: CoreDiagnostic(
                failures: failures,
                skipped: skipped
            )
        )
    }

    @MainActor
    private static func record(
        section: String,
        step: String,
        clock: ContinuousClock,
        startedAt: ContinuousClock.Instant,
        output: inout [String],
        failures: inout [CoreDiagnostic.Failure],
        operation: () throws -> Void
    ) {
        do {
            try operation()
            output.append("step - \(step) [success] [\(elapsed(clock: clock, startedAt: startedAt))]")
        } catch let Failure.failed(failureSection, failureStep, detail) {
            let failure = CoreDiagnostic.Failure(
                section: failureSection,
                step: failureStep,
                detail: detail
            )
            failures.append(failure)
            output.append("step - \(step) [failed] [\(elapsed(clock: clock, startedAt: startedAt))] \(failure.detail)")
        } catch {
            let failure = CoreDiagnostic.Failure(
                section: section,
                step: step,
                detail: error.localizedDescription
            )
            failures.append(failure)
            output.append("step - \(step) [failed] [\(elapsed(clock: clock, startedAt: startedAt))] \(failure.detail)")
        }
    }

    private static func elapsed(
        clock: ContinuousClock,
        startedAt: ContinuousClock.Instant
    ) -> String {
        let duration = startedAt.duration(to: clock.now)
        let components = duration.components
        let seconds = Double(components.seconds)
            + Double(components.attoseconds) / 1_000_000_000_000_000_000
        return String(format: "%.3fs", seconds)
    }

    private static func checkDirectory(_ url: URL, name: String) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw Failure.failed(
                section: "initialize",
                step: "\(name)/",
                detail: "missing directory: \(url.path)"
            )
        }
    }

    private static func checkModeFile() throws {
        do {
            let data = try Data(contentsOf: Config.modeURL)
            _ = try JSONDecoder().decode(CapabilityPolicy.self, from: data)
        } catch {
            throw Failure.failed(
                section: "initialize",
                step: "mode.json",
                detail: "invalid mode.json: \(error.localizedDescription)"
            )
        }
    }

    private static func checkModulesFile() throws {
        do {
            let data = try Data(contentsOf: Config.modulesURL)
            _ = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw Failure.failed(
                section: "initialize",
                step: "modules.json",
                detail: "invalid modules.json: \(error.localizedDescription)"
            )
        }
    }

    private static func checkRegistryFile() throws {
        let registryURL = Bundle.main.resourceURL!
            .appendingPathComponent("Registry", isDirectory: true)
            .appendingPathComponent("registry.db")

        do {
            let handle = try FileHandle(forReadingFrom: registryURL)
            defer { try? handle.close() }
            let header = try handle.read(upToCount: 16) ?? Data()
            guard String(data: header, encoding: .utf8) == "SQLite format 3\0" else {
                throw Failure.failed(
                    section: "initialize",
                    step: "registry.db",
                    detail: "registry.db is not a SQLite database"
                )
            }
        } catch let failure as Failure {
            throw failure
        } catch {
            throw Failure.failed(
                section: "initialize",
                step: "registry.db",
                detail: "cannot read registry.db: \(error.localizedDescription)"
            )
        }
    }

    private static func withRestoredPolicy(
        core: SheoCore,
        originalData: Data,
        originalPolicy: CapabilityPolicy,
        operation: () throws -> Void
    ) throws {
        let backupURL = Config.modeURL.appendingPathExtension("org")
        try? FileManager.default.removeItem(at: backupURL)
        try originalData.write(to: backupURL, options: .atomic)

        var operationError: Error?
        do {
            try operation()
        } catch {
            operationError = error
        }

        var restoreError: Error?
        do {
            try originalData.write(to: Config.modeURL, options: .atomic)
            try waitForMode(originalPolicy.profile.mode, core: core)
            try FileManager.default.removeItem(at: backupURL)
        } catch {
            restoreError = error
        }

        if let restoreError {
            throw Failure.failed(
                section: "permission",
                step: "restore",
                detail: "failed to restore original mode.json: \(restoreError.localizedDescription)"
            )
        }

        if let operationError {
            throw operationError
        }
    }

    private static func activate(_ mode: CapabilityMode, core: SheoCore) throws {
        var policy = try JSONDecoder().decode(
            CapabilityPolicy.self,
            from: Data(contentsOf: Config.modeURL)
        )
        policy.profile.mode = mode

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(policy).write(to: Config.modeURL, options: .atomic)
        try waitForMode(mode, core: core)
    }

    private static func waitForMode(_ mode: CapabilityMode, core: SheoCore) throws {
        let deadline = Date().addingTimeInterval(2)

        while Date() < deadline {
            if core.capabilityMode() == mode {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }

        throw Failure.failed(
            section: "permission",
            step: "mode reload",
            detail: "running Core did not observe mode \(mode.rawValue)"
        )
    }

    private static func expectAllowed(path: String, core: SheoCore, mode: String) throws {
        do {
            _ = try core.readProtected(URL(fileURLWithPath: path))
        } catch {
            throw Failure.failed(
                section: "permission",
                step: "user permission \(mode)",
                detail: "expected ACCESS for \(path), got \(error.localizedDescription)"
            )
        }
    }

    private static func expectDenied(path: String, core: SheoCore, mode: String) throws {
        do {
            _ = try core.readProtected(URL(fileURLWithPath: path))
            throw Failure.failed(
                section: "permission",
                step: "user permission \(mode)",
                detail: "expected NO ACCESS for \(path), protected read succeeded"
            )
        } catch is Failure {
            throw Failure.failed(
                section: "permission",
                step: "user permission \(mode)",
                detail: "expected NO ACCESS for \(path), protected read succeeded"
            )
        } catch {
            return
        }
    }
}

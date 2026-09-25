//
//  SheoCore.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation
import Combine

@MainActor
final class SheoCore: ObservableObject {

    enum State: Equatable {
        case booting
        case ready
        case sovngarde(CoreDiagnostic)
    }

    @Published private(set) var state: State
    @Published private(set) var capabilityPolicy: CapabilityPolicy

    private let capabilityStore: CapabilityStore

    init(capabilityStore: CapabilityStore) {
        self.capabilityStore = capabilityStore

        capabilityPolicy = (try? capabilityStore.load()) ?? CapabilityPolicy()
        state = .booting

        try? capabilityStore.watch { [weak self] in
            Task { @MainActor [weak self] in
                self?.reloadCapabilityPolicy()
            }
        }
    }

    convenience init() {
        self.init(capabilityStore: CapabilityStore())
    }

    func startupCompleted(_ diagnostic: CoreDiagnostic) {
        guard state == .booting else { return }

        if diagnostic.passed {
            state = .ready
        } else {
            state = .sovngarde(diagnostic)
        }
    }

    func capabilityMode() -> CapabilityMode {
        capabilityPolicy.profile.mode
    }

    func canAccess(_ url: URL) -> Bool {
        switch state {
        case .ready, .booting:
            return CapabilityManager(profile: capabilityPolicy.profile).canAccess(url)
        case .sovngarde:
            return isInsideInstallation(url)
        }
    }

    func readProtected(_ url: URL, maximumBytes: Int = 4096) throws -> Data {
        guard canAccess(url) else {
            throw CocoaError(.fileReadNoPermission)
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        ) else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        if isDirectory.boolValue {
            let handle = try FileHandle(forReadingFrom: url)
            try handle.close()
            return Data()
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer {
            try? handle.close()
        }

        return try handle.read(upToCount: maximumBytes) ?? Data()
    }

    func setCapabilityMode(_ mode: CapabilityMode) throws {
        var updatedPolicy = capabilityPolicy
        updatedPolicy.profile.mode = mode
        try save(updatedPolicy)
    }

    func addAllowedPath(_ path: String) throws {
        var updatedPolicy = capabilityPolicy

        if !updatedPolicy.profile.pelagiusIIIAllowedPaths.contains(path) {
            updatedPolicy.profile.pelagiusIIIAllowedPaths.append(path)
        }

        try save(updatedPolicy)
    }

    func removeAllowedPath(_ path: String) throws {
        var updatedPolicy = capabilityPolicy
        updatedPolicy.profile.pelagiusIIIAllowedPaths.removeAll { $0 == path }
        try save(updatedPolicy)
    }

    func addDeniedPath(_ path: String) throws {
        var updatedPolicy = capabilityPolicy

        if !updatedPolicy.profile.wabbajackDeniedPaths.contains(path) {
            updatedPolicy.profile.wabbajackDeniedPaths.append(path)
        }

        try save(updatedPolicy)
    }

    func removeDeniedPath(_ path: String) throws {
        var updatedPolicy = capabilityPolicy
        updatedPolicy.profile.wabbajackDeniedPaths.removeAll { $0 == path }
        try save(updatedPolicy)
    }

    private func isInsideInstallation(_ url: URL) -> Bool {
        let installationURL = Bundle.main.bundleURL.standardizedFileURL.resolvingSymlinksInPath()
        let targetURL = url.standardizedFileURL.resolvingSymlinksInPath()
        let installationPath = installationURL.path.hasSuffix("/")
            ? installationURL.path
            : installationURL.path + "/"

        return targetURL.path == installationURL.path || targetURL.path.hasPrefix(installationPath)
    }

    private func reloadCapabilityPolicy() {
        do {
            capabilityPolicy = try capabilityStore.load()
            if state == .ready {
                state = .ready
            }
        } catch {
            state = .sovngarde(
                CoreDiagnostic(
                    failures: [
                        CoreDiagnostic.Failure(
                            section: "capability",
                            step: "reload policy",
                            detail: error.localizedDescription
                        )
                    ],
                    skipped: []
                )
            )
        }
    }

    private func save(_ policy: CapabilityPolicy) throws {
        try capabilityStore.save(policy)
        capabilityPolicy = policy
    }
}

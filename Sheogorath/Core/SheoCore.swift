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
        case ready
        case oblivionMode(String)
    }

    @Published private(set) var state: State
    @Published private(set) var capabilityPolicy: CapabilityPolicy

    private let capabilityStore: CapabilityStore

    init(capabilityStore: CapabilityStore) {
        self.capabilityStore = capabilityStore

        do {
            capabilityPolicy = try capabilityStore.load()
            state = .ready
        } catch {
            capabilityPolicy = CapabilityPolicy()
            state = .oblivionMode(error.localizedDescription)
        }
    }

    convenience init() {
        self.init(capabilityStore: CapabilityStore())
    }

    func capabilityMode(for context: ClientContext) -> CapabilityMode {
        capabilityPolicy.profile(for: context.type).mode
    }

    func canAccess(_ url: URL, context: ClientContext) -> Bool {
        guard state == .ready else { return false }
        let profile = capabilityPolicy.profile(for: context.type)
        return CapabilityManager(profile: profile).canAccess(url)
    }

    func canAccess(_ url: URL, from client: ClientType) -> Bool {
        canAccess(url, context: ClientContext(type: client))
    }

    func setCapabilityMode(_ mode: CapabilityMode, context: ClientContext) throws {
        var updatedPolicy = capabilityPolicy
        var profile = updatedPolicy.profile(for: context.type)
        profile.mode = mode
        setProfile(profile, for: context.type, in: &updatedPolicy)
        try save(updatedPolicy)
    }

    func addAllowedPath(_ path: String, context: ClientContext) throws {
        var updatedPolicy = capabilityPolicy
        var profile = updatedPolicy.profile(for: context.type)

        if !profile.pelagiusIIIAllowedPaths.contains(path) {
            profile.pelagiusIIIAllowedPaths.append(path)
        }

        setProfile(profile, for: context.type, in: &updatedPolicy)
        try save(updatedPolicy)
    }

    func removeAllowedPath(_ path: String, context: ClientContext) throws {
        var updatedPolicy = capabilityPolicy
        var profile = updatedPolicy.profile(for: context.type)
        profile.pelagiusIIIAllowedPaths.removeAll { $0 == path }
        setProfile(profile, for: context.type, in: &updatedPolicy)
        try save(updatedPolicy)
    }

    func addDeniedPath(_ path: String, context: ClientContext) throws {
        var updatedPolicy = capabilityPolicy
        var profile = updatedPolicy.profile(for: context.type)

        if !profile.wabbajackDeniedPaths.contains(path) {
            profile.wabbajackDeniedPaths.append(path)
        }

        setProfile(profile, for: context.type, in: &updatedPolicy)
        try save(updatedPolicy)
    }

    func removeDeniedPath(_ path: String, context: ClientContext) throws {
        var updatedPolicy = capabilityPolicy
        var profile = updatedPolicy.profile(for: context.type)
        profile.wabbajackDeniedPaths.removeAll { $0 == path }
        setProfile(profile, for: context.type, in: &updatedPolicy)
        try save(updatedPolicy)
    }

    private func setProfile(
        _ profile: CapabilityProfile,
        for client: ClientType,
        in policy: inout CapabilityPolicy
    ) {
        switch client {
        case .native:
            policy.native = profile
        case .terminal:
            policy.terminal = profile
        case .web:
            policy.web = profile
        }
    }

    private func save(_ policy: CapabilityPolicy) throws {
        try capabilityStore.save(policy)
        capabilityPolicy = policy
    }
}

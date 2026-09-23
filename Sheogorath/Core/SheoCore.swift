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
    @Published private(set) var capabilityPolicy: CapabilityPolicy

    private let capabilityStore: CapabilityStore

    init(capabilityStore: CapabilityStore) {
        self.capabilityStore = capabilityStore
        capabilityPolicy = capabilityStore.load()
    }

    convenience init() {
        self.init(capabilityStore: CapabilityStore())
    }

    func capabilityMode(for context: ClientContext) -> CapabilityMode {
        capabilityPolicy.profile(for: context.type).mode
    }

    func canAccess(_ url: URL, context: ClientContext) -> Bool {
        let profile = capabilityPolicy.profile(for: context.type)
        return CapabilityManager(profile: profile).canAccess(url)
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

//
//  CapabilityPolicy.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation


struct CapabilityPolicy: Codable, Sendable, Equatable {
    var native: CapabilityProfile
    var terminal: CapabilityProfile
    var web: CapabilityProfile

    init(
        native: CapabilityProfile = CapabilityProfile(),
        terminal: CapabilityProfile = CapabilityProfile(),
        web: CapabilityProfile = CapabilityProfile()
    ) {
        self.native = native
        self.terminal = terminal
        self.web = web
    }

    func profile(for client: ClientType) -> CapabilityProfile {
        switch client {
        case .native:
            return native
        case .terminal:
            return terminal
        case .web:
            return web
        }
    }
}

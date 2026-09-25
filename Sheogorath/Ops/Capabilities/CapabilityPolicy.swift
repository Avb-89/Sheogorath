//
//  CapabilityPolicy.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation


struct CapabilityPolicy: Codable, Sendable, Equatable {
    var profile: CapabilityProfile

    init(profile: CapabilityProfile = CapabilityProfile()) {
        self.profile = profile
    }
}

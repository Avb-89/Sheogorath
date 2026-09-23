//
//  CapabilityProfile.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct CapabilityProfile: Codable, Sendable, Equatable {
    var mode: CapabilityMode
    var pelagiusIIIAllowedPaths: [String]
    var wabbajackDeniedPaths: [String]

    init(
        mode: CapabilityMode = .pelagiusIII,
        pelagiusIIIAllowedPaths: [String] = [],
        wabbajackDeniedPaths: [String] = []
    ) {
        self.mode = mode
        self.pelagiusIIIAllowedPaths = pelagiusIIIAllowedPaths
        self.wabbajackDeniedPaths = wabbajackDeniedPaths
    }
}

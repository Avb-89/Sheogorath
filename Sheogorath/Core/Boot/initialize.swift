//
//  initialize.swift
//  Sheogorath
//
//  Created by SITIS on 9/25/26.
//

import Foundation

enum Installation {
    enum State: Equatable {
        case uninitialized
        case initialized
    }

    static var state: State {
        FileManager.default.fileExists(atPath: Config.factoryMarkerURL.path)
            ? .initialized
            : .uninitialized
    }

    static func initialize() throws {
        guard state == .uninitialized else { return }
        try FactoryDefaults.generateFactoryDefaults()
    }
}

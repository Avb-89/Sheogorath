//
//  Config.swift
//  Sheogorath
//
//  Created by SITIS on 9/25/26.
//

import Foundation

enum Config {
    static let directoryName = "Configs"
    static let modeFileName = "mode.json"
    static let modulesFileName = "modules.json"
    static let factoryMarkerFileName = ".sheofrun"

    static var directoryURL: URL {
        Bundle.main.resourceURL!
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    static var modeURL: URL {
        directoryURL.appendingPathComponent(modeFileName)
    }

    static var modulesURL: URL {
        directoryURL.appendingPathComponent(modulesFileName)
    }

    static var factoryMarkerURL: URL {
        Bundle.main.resourceURL!
            .appendingPathComponent(factoryMarkerFileName)
    }
}

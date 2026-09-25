//
//  FactoryDefaults.swift
//  Sheogorath
//
//  Created by SITIS on 9/25/26.
//

import Foundation
import SQLite3

enum FactoryDefaults {

    static func generateFactoryDefaults() throws {
        let resourcesURL = Bundle.main.resourceURL!
        let manualsURL = resourcesURL.appendingPathComponent("Manuals", isDirectory: true)
        let modulesURL = resourcesURL.appendingPathComponent("Modules", isDirectory: true)
        let logsURL = resourcesURL.appendingPathComponent("Logs", isDirectory: true)
        let registryURL = resourcesURL.appendingPathComponent("Registry", isDirectory: true)
        let registryDatabaseURL = registryURL.appendingPathComponent("registry.db")

        try FileManager.default.createDirectory(
            at: Config.directoryURL,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: manualsURL,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: modulesURL,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: logsURL,
            withIntermediateDirectories: true
        )

        try FileManager.default.createDirectory(
            at: registryURL,
            withIntermediateDirectories: true
        )

        if !FileManager.default.fileExists(atPath: Config.modeURL.path) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(CapabilityPolicy())
            try data.write(to: Config.modeURL, options: .atomic)
        }

        if !FileManager.default.fileExists(atPath: Config.modulesURL.path) {
            let data = try JSONSerialization.data(
                withJSONObject: ["modules": []],
                options: [.prettyPrinted, .sortedKeys]
            )
            try data.write(to: Config.modulesURL, options: .atomic)
        }

        if !FileManager.default.fileExists(atPath: registryDatabaseURL.path) {
            var database: OpaquePointer?
            let openResult = sqlite3_open(registryDatabaseURL.path, &database)

            guard openResult == SQLITE_OK, let database else {
                if database != nil {
                    sqlite3_close(database)
                }
                throw CocoaError(.fileWriteUnknown)
            }

            let initializeResult = sqlite3_exec(
                database,
                "PRAGMA user_version = 0;",
                nil,
                nil,
                nil
            )

            guard initializeResult == SQLITE_OK else {
                sqlite3_close(database)
                throw CocoaError(.fileWriteUnknown)
            }

            sqlite3_close(database)
        }

        if !FileManager.default.fileExists(atPath: Config.factoryMarkerURL.path) {
            try Data("1\n".utf8).write(to: Config.factoryMarkerURL, options: .atomic)
        }
    }
}

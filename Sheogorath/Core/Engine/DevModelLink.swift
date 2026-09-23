//
//  DevModelLink.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

// УДАЛИТЬ НА РЕЛИЗЕ
enum DevModelLink {
    static func install() throws {
        let fileManager = FileManager.default
        let appURL = Bundle.main.bundleURL
        let linkURL = appURL.appendingPathComponent("Contents/LLM")
        let targetURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("LLM")

        if fileManager.fileExists(atPath: linkURL.path) {
            return
        }

        try fileManager.createSymbolicLink(
            at: linkURL,
            withDestinationURL: targetURL
        )
    }
}
// УДАЛИТЬ НА РЕЛИЗЕ

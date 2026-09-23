//
//  CapabilityManager.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct CapabilityManager: Sendable {
    private let profile: CapabilityProfile

    init(profile: CapabilityProfile) {
        self.profile = profile
    }

    func canAccess(_ url: URL) -> Bool {
        let requestedPath = canonicalPath(url)

        switch profile.mode {
        case .pelagiusIII:
            return profile.pelagiusIIIAllowedPaths.contains {
                contains(requestedPath, inside: canonicalPath($0))
            }

        case .wabbajack:
            return !profile.wabbajackDeniedPaths.contains {
                contains(requestedPath, inside: canonicalPath($0))
            }
        }
    }

    private func canonicalPath(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }

    private func canonicalPath(_ path: String) -> String {
        let expandedPath = NSString(string: path).expandingTildeInPath
        return canonicalPath(URL(fileURLWithPath: expandedPath))
    }

    private func contains(_ requestedPath: String, inside rootPath: String) -> Bool {
        requestedPath == rootPath || requestedPath.hasPrefix(rootPath + "/")
    }
}

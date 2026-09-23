//
//  CapabilityTests.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

#if DEBUG
enum CapabilityTests {
    static func run() -> [String] {
        var results: [String] = []

        check(
            "PelagiusIII denies unknown path",
            expected: false,
            actual: manager(
                mode: .pelagiusIII,
                allowed: ["~/Projects"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Documents/file.txt")),
            results: &results
        )

        check(
            "PelagiusIII allows configured path",
            expected: true,
            actual: manager(
                mode: .pelagiusIII,
                allowed: ["~/Projects"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Projects")),
            results: &results
        )

        check(
            "PelagiusIII allows child path",
            expected: true,
            actual: manager(
                mode: .pelagiusIII,
                allowed: ["~/Projects"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Projects/App/file.swift")),
            results: &results
        )

        check(
            "PelagiusIII rejects similar prefix",
            expected: false,
            actual: manager(
                mode: .pelagiusIII,
                allowed: ["~/Projects"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Projects-Evil/file.swift")),
            results: &results
        )

        check(
            "WABBAJACK allows unknown path",
            expected: true,
            actual: manager(
                mode: .wabbajack,
                denied: ["~/Secrets"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Documents/file.txt")),
            results: &results
        )

        check(
            "WABBAJACK denies configured path",
            expected: false,
            actual: manager(
                mode: .wabbajack,
                denied: ["~/Secrets"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Secrets")),
            results: &results
        )

        check(
            "WABBAJACK denies child path",
            expected: false,
            actual: manager(
                mode: .wabbajack,
                denied: ["~/Secrets"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Secrets/private.txt")),
            results: &results
        )

        check(
            "WABBAJACK allows similar prefix",
            expected: true,
            actual: manager(
                mode: .wabbajack,
                denied: ["~/Secrets"]
            ).canAccess(URL(fileURLWithPath: NSHomeDirectory() + "/Secrets-Other/file.txt")),
            results: &results
        )

        check(
            "Default Native profile is PelagiusIII",
            expected: CapabilityMode.pelagiusIII,
            actual: CapabilityPolicy().profile(for: .native).mode,
            results: &results
        )

        check(
            "Default Terminal profile is PelagiusIII",
            expected: CapabilityMode.pelagiusIII,
            actual: CapabilityPolicy().profile(for: .terminal).mode,
            results: &results
        )

        check(
            "Default Web profile is PelagiusIII",
            expected: CapabilityMode.pelagiusIII,
            actual: CapabilityPolicy().profile(for: .web).mode,
            results: &results
        )

        check(
            "Default PelagiusIII denies everything",
            expected: false,
            actual: CapabilityManager(
                profile: CapabilityPolicy().profile(for: .native)
            ).canAccess(
                URL(fileURLWithPath: NSHomeDirectory() + "/anything")
            ),
            results: &results
        )

        return results
    }

    private static func manager(
        mode: CapabilityMode,
        allowed: [String] = [],
        denied: [String] = []
    ) -> CapabilityManager {
        CapabilityManager(
            profile: CapabilityProfile(
                mode: mode,
                pelagiusIIIAllowedPaths: allowed,
                wabbajackDeniedPaths: denied
            )
        )
    }

    private static func check<T: Equatable>(
        _ name: String,
        expected: T,
        actual: T,
        results: inout [String]
    ) {
        let status = expected == actual ? "PASS" : "FAIL"
        results.append("[\(status)] \(name)")
    }
}
#endif

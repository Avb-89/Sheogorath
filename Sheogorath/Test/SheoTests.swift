//
//  SheoTests.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

#if DEBUG
enum SheoTests {
    static func run() {
        let capabilityResults = CapabilityTests.run()
        let terminalResults = TerminalShellTests.run()
        let coreStateResults = CoreStateTests.run()
        let allResults = capabilityResults + terminalResults + coreStateResults
        let passed = allResults.filter { $0.hasPrefix("[PASS]") }.count
        let failed = allResults.count - passed

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("Sheogorath Self Test")
        print("Run: \(formatter.string(from: Date()))")
        print("────────────────────")

        for result in allResults {
            print(result)
        }

        print("────────────────────")
        let capabilityPassed = capabilityResults.filter { $0.hasPrefix("[PASS]") }.count
        let terminalPassed = terminalResults.filter { $0.hasPrefix("[PASS]") }.count
        let coreStatePassed = coreStateResults.filter { $0.hasPrefix("[PASS]") }.count

        print("Capabilities: \(capabilityPassed)/\(capabilityResults.count) PASS")
        print("Terminal Shell: \(terminalPassed)/\(terminalResults.count) PASS")
        print("Core State: \(coreStatePassed)/\(coreStateResults.count) PASS")
        print("Total failures: \(failed)")
    }
}
#endif

//
//  SheoTests.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

#if DEBUG
enum SheoTests {
    static func run() {
        let capabilityResults = CapabilityTests.run()
        let passed = capabilityResults.filter { $0.hasPrefix("[PASS]") }.count
        let failed = capabilityResults.count - passed

        print("Sheogorath Self Test")
        print("────────────────────")

        for result in capabilityResults {
            print(result)
        }

        print("────────────────────")
        print("Capabilities: \(passed)/\(capabilityResults.count) PASS")
        print("Total failures: \(failed)")
    }
}
#endif

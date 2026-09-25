//
//  CoreDiagnostic.swift
//  Sheogorath
//
//  Created by SITIS on 9/25/26.
//

import Foundation

struct CoreDiagnostic: Equatable {
    struct Failure: Equatable {
        let section: String
        let step: String
        let detail: String
    }

    struct Skipped: Equatable {
        let section: String
        let step: String
        let detail: String
    }

    let failures: [Failure]
    let skipped: [Skipped]

    var passed: Bool {
        failures.isEmpty
    }
}

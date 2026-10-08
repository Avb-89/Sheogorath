//
//  TerminalShell.swift
//  Sheogorath
//
//  Created by SITIS on 9/24/26.
//

import Foundation

@MainActor
struct TerminalShell {
    private let shell: CoreShell

    init(core: SheoCore) {
        shell = core.shell
    }

    mutating func execute(_ input: String) async -> String {
        await shell.execute(input)
    }
}

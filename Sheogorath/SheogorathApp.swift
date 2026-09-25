//
//  SheogorathApp.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct SheogorathApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @StateObject private var core: SheoCore

    @MainActor
    init() {
        var bootDiagnostic: CoreDiagnostic?

        if Installation.state == .uninitialized {
            do {
                try Installation.initialize()
            } catch {
                bootDiagnostic = CoreDiagnostic(
                    failures: [
                        CoreDiagnostic.Failure(
                            section: "boot",
                            step: "factory",
                            detail: error.localizedDescription
                        )
                    ],
                    skipped: []
                )
            }
        }

        let core = SheoCore()
        _core = StateObject(wrappedValue: core)

        if let bootDiagnostic {
            core.startupCompleted(bootDiagnostic)
            return
        }

        let result = SelfCheckTest.run(core: core)
        core.startupCompleted(result.diagnostic)

        do {
            try CoreLog.append(result.report + [""])
        } catch {
#if DEBUG
            print("[core-log FAILED]")
            print(String(describing: error))
#endif
        }

#if DEBUG
        for line in result.report {
            print(line)
        }
#endif
    }

    var body: some Scene {
        MenuBarExtra("Sheogorath", systemImage: "sparkles") {
            Button("Open Sheogorath") {
                openWindow(id: "chat")
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Quit Sheogorath") {
                NSApp.terminate(nil)
            }
        }

        Window("Sheogorath", id: "chat") {
            ChatUI()
                .environmentObject(core)
        }
        .defaultSize(width: 760, height: 560)
    }
}


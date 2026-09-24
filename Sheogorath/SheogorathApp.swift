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

    init() {
        // УДАЛИТЬ НА РЕЛИЗЕ
#if DEBUG
        SheoTests.run()
#endif
        // УДАЛИТЬ НА РЕЛИЗЕ
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
        }
        .defaultSize(width: 760, height: 560)
    }
}

//
//  SheogorathApp.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import SwiftUI

@main
struct SheogorathApp: App {
    @Environment(\.openWindow) private var openWindow

    // УДАЛИТЬ НА РЕЛИЗЕ
    init() {
#if DEBUG
        SheoTests.run()
#endif
        try? DevModelLink.install()

        do {
            let header = try InferenceEngine().readModelHeader()
            print("GGUF version: \(header.version)")
            print("GGUF tensors: \(header.tensorCount)")
            print("GGUF metadata: \(header.metadataCount)")
        } catch {
            print("GGUF error: \(error)")
        }
    }
    // УДАЛИТЬ НА РЕЛИЗЕ

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

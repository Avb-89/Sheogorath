//
//  InferenceEngine.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct InferenceEngine: Sendable {
    private let modelURL: URL

    init() {
        modelURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/LLM/Sheogorath.gguf")
    }

    func readModelHeader() throws -> GGUFHeader {
        try GGUFReader.readHeader(from: modelURL)
    }
}

//
//  LLMEngine.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct LLMEngine: Sendable {
    private let inference: InferenceEngine

    init(inference: InferenceEngine = InferenceEngine()) {
        self.inference = inference
    }
}

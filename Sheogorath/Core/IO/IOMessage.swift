//
//  IOMessage.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct IOMessage: Identifiable, Codable, Equatable, Sendable {
    enum Source: String, Codable, Sendable {
        case user
        case core
        case module
    }

    enum Kind: String, Codable, Sendable {
        case input
        case output
        case progress
        case result
        case error
    }

    let id: UUID
    let source: Source
    let kind: Kind
    let content: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        source: Source,
        kind: Kind,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.kind = kind
        self.content = content
        self.createdAt = createdAt
    }
}

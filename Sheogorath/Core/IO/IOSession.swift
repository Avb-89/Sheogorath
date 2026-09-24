//
//  ChatSession.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation

struct ChatSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    private(set) var messages: [Message]

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        messages: [Message] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.messages = messages
    }

    mutating func append(_ message: Message) {
        messages.append(message)
        updatedAt = message.createdAt
    }

    mutating func rename(to title: String) {
        self.title = title
        updatedAt = Date()
    }
}

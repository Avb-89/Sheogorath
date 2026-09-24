//
//  ChatManager.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation
import Combine

@MainActor
final class ChatManager: ObservableObject {
    @Published private(set) var chats: [ChatSession] = []
    @Published private(set) var activeChatID: UUID?

    var activeChat: ChatSession? {
        guard let activeChatID else { return nil }
        return chats.first { $0.id == activeChatID }
    }

    @discardableResult
    func createChat(title: String = "New Chat") -> UUID {
        let chat = ChatSession(title: title)
        chats.insert(chat, at: 0)
        activeChatID = chat.id
        return chat.id
    }

    func selectChat(_ id: UUID) {
        guard chats.contains(where: { $0.id == id }) else { return }
        activeChatID = id
    }

    func append(_ message: Message, to chatID: UUID) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].append(message)
    }

    func renameChat(_ id: UUID, to title: String) {
        guard let index = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[index].rename(to: title)
    }

    func deleteChat(_ id: UUID) {
        chats.removeAll { $0.id == id }

        if activeChatID == id {
            activeChatID = chats.first?.id
        }
    }
}

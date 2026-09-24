//
//  IOManager.swift
//  Sheogorath
//
//  Created by SITIS on 9/23/26.
//

import Foundation
import Combine

@MainActor
final class IOManager: ObservableObject {
    @Published private(set) var sessions: [IOSession] = []
    @Published private(set) var activeSessionID: UUID?

    var activeSession: IOSession? {
        guard let activeSessionID else { return nil }
        return sessions.first { $0.id == activeSessionID }
    }

    @discardableResult
    func createSession(title: String = "New Session") -> UUID {
        let session = IOSession(title: title)
        sessions.insert(session, at: 0)
        activeSessionID = session.id
        return session.id
    }

    func selectSession(_ id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        activeSessionID = id
    }

    func append(_ message: IOMessage, to sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].append(message)
    }

    func renameSession(_ id: UUID, to title: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].rename(to: title)
    }

    func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }

        if activeSessionID == id {
            activeSessionID = sessions.first?.id
        }
    }
}

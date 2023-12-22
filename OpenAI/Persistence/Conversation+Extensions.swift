//
//  Conversation+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/30/23.
//

import Foundation

extension Conversation {
    func messagesArray() -> [Message]? {
        return (messages?.allObjects as? [Message])?.sorted { $0.createdAt?.timeIntervalSince($1.createdAt ?? Date()) ?? 0 >= 0 }
//        return self.messages.flatMap { $0.array as? [Message] } ?? []
    }
}


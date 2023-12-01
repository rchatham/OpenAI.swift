//
//  Conversation+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/30/23.
//

import Foundation

extension Conversation {
    func messagesArray() -> [Message] {
        return (self.messages?.allObjects as? [Message]) ?? []
    }
}


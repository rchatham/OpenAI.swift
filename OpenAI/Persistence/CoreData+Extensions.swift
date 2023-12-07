//
//  CoreData+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation
import openai_swift

extension Message {
    func toNetworkMessage() -> OpenAI.Message? {
        guard let content = content, let role = role else { return nil }
        return OpenAI.Message(role: role, content: content)
    }
}

// Conversion functions for Conversation and Message Core Data models
extension Conversation {
    func toNetworkMessages() -> [OpenAI.Message] {
        let systemMessageString = self.systemMessage ?? "You are a friendly chatbot designed to be helpful. Always be nice, but if you don't have a clear understanding of what should come next, try to indicate that."
        let systemMessage = OpenAI.Message(role: .system, content: systemMessageString)
        guard let messages = self.messages else { return [systemMessage] }
        return [systemMessage] + messages.sorted(by: { ($0 as? Message)?.createdAt ?? Date() < ($1 as? Message)?.createdAt ?? Date() }).compactMap { ($0 as? Message)?.toNetworkMessage() }
    }
}


import CoreData

// Conversion functions for OpenAIChatAPI.ChatCompletionRequest and OpenAIChatAPI.ChatCompletionResponse models
extension OpenAI.Message {
    func toCoreDataMessage(in context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.roleString = role.rawValue
        message.content = content
        message.createdAt = Date()
        message.id = UUID()
        return message
    }

    func toDictionary() -> [String: Any] {
        return [
            "role": role.rawValue,
            "content": content
        ]
    }

    func toCoreDataMessage(in context: NSManagedObjectContext, for conversation: Conversation) -> Message {
        let message = Message(context: context)
        message.roleString = role.rawValue
        message.content = content
        message.createdAt = Date()
        message.id = UUID()
        message.conversation = conversation
        conversation.addToMessages(message)
        return message
    }
}

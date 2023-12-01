//
//  CoreData+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation


extension Message {
    func toNetworkMessage() -> OpenAIChatAPI.Message? {
        guard let content = content, let role = role else { return nil }
        return OpenAIChatAPI.Message(role: role, content: content)
    }
}

// Conversion functions for Conversation and Message Core Data models
extension Conversation {
    func toNetworkMessages() -> [OpenAIChatAPI.Message] {
        let systemMessageString = self.systemMessage ?? "You are a friendly chatbot designed to be helpful. Always be nice, but if you don't have a clear understanding of what should come next, try to indicate that."
        let systemMessage = OpenAIChatAPI.Message(role: .system, content: systemMessageString)
        guard let messages = self.messages else { return [systemMessage] }
        return [systemMessage] + messages.sorted(by: { ($0 as? Message)?.createdAt ?? Date() < ($1 as? Message)?.createdAt ?? Date() }).compactMap { ($0 as? Message)?.toNetworkMessage() }
    }
}


import CoreData

// Conversion functions for OpenAIChatAPI.ChatCompletionRequest and OpenAIChatAPI.ChatCompletionResponse models
extension OpenAIChatAPI.Message {
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

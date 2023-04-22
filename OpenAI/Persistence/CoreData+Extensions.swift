//
//  CoreData+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation

// Conversion functions for Conversation and Message Core Data models
extension Conversation {
    func toNetworkMessages() -> [ChatCompletionRequest.Message] {
        let systemMessageString = self.systemMessage ?? "You are a friendly chatbot designed to be helpful. Always be nice, but if you don't have a clear understanding of what should come next, try to indicate that."
        let systemMessage = ChatCompletionRequest.Message(role: .system, content: systemMessageString)
        guard let messages = self.messages else { return [systemMessage] }
        return [systemMessage] + messages.sorted(by: { ($0 as? Message)?.createdAt ?? Date() < ($1 as? Message)?.createdAt ?? Date() }).compactMap { ($0 as? Message)?.toNetworkMessage() }
    }
}

extension Message {
    func toNetworkMessage() -> ChatCompletionRequest.Message? {
        guard let roleString = role, let content = content, let role = Role(rawValue: roleString) else { return nil }
        return ChatCompletionRequest.Message(role: role, content: content)
    }
}

extension Conversation {
    func messagesArray() -> [Message] {
        return (self.messages?.allObjects as? [Message]) ?? []
    }
}

extension Message {
    static var example: Message {
        let context = PersistenceController.preview.container.viewContext
        
        let message = Message(context: context)
        message.id = UUID()
        message.content = "This is a sample message."
        message.role = "user"
        message.createdAt = Date()
        
        // Save the context to store the message in the database
        do {
            try context.save()
        } catch {
            print("Error saving sample message: \(error)")
        }
        
        return message
    }
}

extension Conversation {
    static var example: Conversation {
        let conversation = Conversation(context: PersistenceController.preview.container.viewContext)
        conversation.title = "Sample Conversation"
        conversation.id = UUID()
        conversation.createdAt = Date()

        let message1 = Message(context: PersistenceController.preview.container.viewContext)
        message1.role = "user"
        message1.content = "Hello, how are you?"
        message1.id = UUID()
        message1.createdAt = Date()

        let message2 = Message(context: PersistenceController.preview.container.viewContext)
        message2.role = "ai"
        message2.content = "I'm doing well, thank you. How can I help you today?"
        message2.id = UUID()
        message2.createdAt = Date().addingTimeInterval(5)

        conversation.addToMessages(message1)
        conversation.addToMessages(message2)

        return conversation
    }
}

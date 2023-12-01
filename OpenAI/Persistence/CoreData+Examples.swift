//
//  CoreData+Examples.swift
//  OpenAI
//
//  Created by Reid Chatham on 11/28/23.
//

import Foundation

extension Message {
    static var example: Message {
        let context = PersistenceController.preview.container.viewContext
        let message = Message(context: context)
        message.id = UUID()
        message.content = "This is a sample message."
        message.roleString = "user"
        message.createdAt = Date()
        // Save the context to store the message in the database
        do { try context.save() }
        catch { print("Error saving sample message: \(error)") }
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
        message1.roleString = "user"
        message1.content = "Hello, how are you?"
        message1.id = UUID()
        message1.createdAt = Date()

        let message2 = Message(context: PersistenceController.preview.container.viewContext)
        message2.roleString = "ai"
        message2.content = "I'm doing well, thank you. How can I help you today?"
        message2.id = UUID()
        message2.createdAt = Date().addingTimeInterval(5)

        conversation.addToMessages(message1)
        conversation.addToMessages(message2)

        return conversation
    }
}

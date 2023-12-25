//
//  CoreData+Examples.swift
//  OpenAI
//
//  Created by Reid Chatham on 11/28/23.
//

import Foundation
import CoreData

extension Message {
    static func example(context: NSManagedObjectContext = PersistenceController.preview.container.viewContext, text: String = "This is a sample message.", type: ContentType = .string, role: Role = .user) -> Message {
        let message = Message(context: context)
        message.id = UUID()
        message.contentText = text
        message.contentType = type
        message.role = role
        message.createdAt = Date()
        // Save the context to store the message in the database
        do { try context.save() }
        catch { print("Error saving sample message: \(error)") }
        return message
    }
}

extension Conversation {
    static func example() -> Conversation {
        let context = PersistenceController.preview.container.viewContext
        let conversation = Conversation(context: context)
        conversation.title = "Sample Conversation"
        conversation.id = UUID()
        conversation.createdAt = Date()
        conversation.addToMessages(Message.example(text: "Hello, how are you?"))
        conversation.addToMessages(Message.example(text: "I'm doing well, thank you. How can I help you today?", role: .assistant))

        do { try context.save() }
        catch { print("Error saving sample message: \(error)") }
        return conversation
    }
}

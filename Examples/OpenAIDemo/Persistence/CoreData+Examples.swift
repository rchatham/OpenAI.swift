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
    static func example(context: NSManagedObjectContext = PersistenceController.preview.container.viewContext) -> Conversation {
        let conversation = Conversation(context: context)
        conversation.title = "Sample Conversation"
        conversation.id = UUID()
        conversation.createdAt = Date()
        conversation.addToMessages(Message.example(context: context, text: "Hello, how are you?"))
        conversation.addToMessages(Message.example(context: context, text: "I'm doing well, thank you. How can I help you today?", role: .assistant))

        do { try context.save() }
        catch { print("Error saving sample conversation: \(error)") }
        return conversation
    }
}

extension ToolCall {
    static func example(context: NSManagedObjectContext = PersistenceController.preview.container.viewContext) -> ToolCall {
        let toolCall = ToolCall(context: context)
        toolCall.id = "some-tool-call-id-string-o87sch8adc"
        toolCall.index = 0
        toolCall.name = "getAnswerToUniverse"
        toolCall.arguments = "{}"
        toolCall.typeString = "function"

        do { try context.save() }
        catch { print("Error saving sample tool call: \(error)") }
        return toolCall
    }
}

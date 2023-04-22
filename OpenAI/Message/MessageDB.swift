//
//  MessageDB.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation
import CoreData
import CloudKit

class MessageDB {
    
    var persistence: PersistenceController
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
    }
    
    @discardableResult
    func createMessage(for conversation: Conversation, with content: String, asUser: Bool = true) -> Message {
        let context = persistence.container.viewContext
        let message = Message(context: context)
        message.role = asUser ? "user" : "assistant"
        message.content = content
        message.createdAt = Date()
        message.id = UUID()
        message.conversation = conversation
        conversation.addToMessages(message)
        do {
            try context.save()
        } catch {
            print("Failed to insert message: \(error)")
        }
        return message
    }
    
    @discardableResult
    func createMessage(for conversation: Conversation, from networkMessage: ChatCompletionResponse.Choice.Message) -> Message {
        let context = persistence.container.viewContext
        let message = networkMessage.toCoreDataMessage(in: context)
        message.conversation = conversation
        conversation.addToMessages(message)
        do {
            try context.save()
        } catch {
            print("Failed to insert message: \(error)")
        }
        return message
    }
    
    func updateMessage(id: UUID, content: String) {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let message = try context.fetch(request).first
            message?.content = content
            try context.save()
        } catch {
            print("Failed to update message: \(error)")
        }
    }

    func deleteMessage(id: UUID) {
        let context = persistence.container.newBackgroundContext()
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let message = try context.fetch(request).first
            if let message = message {
                context.delete(message)
                try context.save()
            }
        } catch {
            print("Failed to delete message: \(error)")
        }
    }

}

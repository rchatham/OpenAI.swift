//
//  MessageDB.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation
import CoreData
import CloudKit
import OpenAI

class MessageDB {
    
    var persistence: PersistenceController
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
    }
    
    @discardableResult
    func createMessage(for conversation: Conversation, content: String, role: Role = .user, name: String? = nil) async -> UUID {
        let context = conversation.managedObjectContext ?? persistence.container.viewContext
        let id = UUID()
        await context.perform {
            Message(context: context).update(contentText: content, contentType: .string, createdAt: Date(), id: id, name: name, role: role, conversation: conversation)
            do { try context.save()} catch { print("Failed to insert message: \(error)")}
        }
        return id
    }

    @discardableResult
    func createToolMessage(for conversation: Conversation, content: String, toolCallId: String, name: String) async -> UUID {
        let context = conversation.managedObjectContext ?? persistence.container.viewContext
        let id = UUID()
        await context.perform {
            Message(context: context).update(contentText: content, contentType: .string, createdAt: Date(), id: id, name: name, role: .tool, toolCallId: toolCallId, conversation: conversation)
            do { try context.save()} catch { print("Failed to insert message: \(error)")}
        }
        return id
    }

    @discardableResult
    func createMessage(for conversation: Conversation, from networkMessage: OpenAI.Message) async -> UUID {
        let context = conversation.managedObjectContext ?? persistence.container.viewContext
        let id = UUID()
        await context.perform {
            networkMessage.toCoreDataMessage(in: context, for: conversation, with: id)
            do { try context.save() } catch { print("Failed to insert message: \(error)") }
        }
        return id
    }
    
    func updateMessage(id: UUID, content: String) async {
        let request = fetchMessage(id)
        let context = persistence.container.viewContext
        await context.perform {
            do {
                try context.fetch(request).first?.contentText = content
                try context.save()
            } catch { print("Failed to update message: \(error)")}
        }
    }

    func updateMessage(id: UUID, toolCalls: [OpenAI.Message.ToolCall]) async {
        let request = fetchMessage(id)
        let context = persistence.container.viewContext
        await context.perform {
            do {
                try toolCalls
                    .map { $0.toCoreDataToolCall(in: context) }
                    .forEach { try context.fetch(request).first?.addToToolCalls($0) }
                try context.save()
            } catch { print("Failed to update message: \(error)")}
        }
    }

    func deleteMessage(id: UUID) {
        let context = persistence.container.newBackgroundContext()
        let request = fetchMessage(id)
        context.perform {
            do { try context.fetch(request).first.flatMap { context.delete($0); try context.save()}}
            catch { print("Failed to delete message: \(error)")}
        }
    }

    private func fetchMessage(_ id: UUID) -> NSFetchRequest<Message> {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return request
    }
}

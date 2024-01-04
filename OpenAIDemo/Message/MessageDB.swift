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
    func createMessage(for conversation: Conversation, content: String, role: Role = .user, name: String? = nil) -> Message {
        let context = persistence.container.viewContext
        let message = Message(context: context).update(contentText: content, contentType: .string, createdAt: Date(), id: UUID(), name: name, role: role, conversation: conversation)
        do { try context.save()} catch { print("Failed to insert message: \(error)")}
        return message
    }

    @discardableResult
    func createToolMessage(for conversation: Conversation, content: String, toolCallId: String, name: String) -> Message {
        let context = persistence.container.viewContext
        let message = Message(context: context).update(contentText: content, contentType: .string, createdAt: Date(), id: UUID(), name: name, role: .tool, toolCallId: toolCallId, conversation: conversation)
        do { try context.save()}
        catch { print("Failed to insert message: \(error)")}
        return message
    }

    @discardableResult
    func createMessage(from networkMessage: OpenAI.Message) -> Message {
        let message = networkMessage.toCoreDataMessage(in: persistence.container.viewContext)
        do { try persistence.container.viewContext.save() }
        catch { print("Failed to insert message: \(error)") }
        return message
    }
    
    func updateMessage(id: UUID, content: String) {
        let context = persistence.container.viewContext
        do { try context.fetch(fetchMessage(id)).first?.contentText = content; try context.save() }
        catch { print("Failed to update message: \(error)")}
    }

    @discardableResult
    func createToolCall(from networkToolCall: OpenAI.Message.ToolCall) -> ToolCall {
        let message = networkToolCall.toCoreDataToolCall(in: persistence.container.viewContext)
        do { try persistence.container.viewContext.save() }
        catch { print("Failed to insert message: \(error)") }
        return message
    }

    func updateMessage(id: UUID, toolCalls: [ToolCall]) {
        let context = persistence.container.viewContext
        do { try toolCalls.forEach { try context.fetch(fetchMessage(id)).first?.addToToolCalls($0) }; try context.save() }
        catch { print("Failed to update message: \(error)")}
    }

    func deleteMessage(id: UUID) {
        let context = persistence.container.newBackgroundContext()
        do { try context.fetch(fetchMessage(id)).first.flatMap { context.delete($0); try context.save()}}
        catch { print("Failed to delete message: \(error)")}
    }

    private func fetchMessage(_ id: UUID) -> NSFetchRequest<Message> {
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return request
    }
}

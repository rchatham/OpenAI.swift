//
//  ConversationDB.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation
import CoreData
import CloudKit

class ConversationDB {
    
    var persistence: PersistenceController
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
    }
    
    func createConversation(title: String, systemMessage: String) -> Conversation {
        let context = persistence.container.viewContext
        let conversation = Conversation(context: context)
        conversation.id = UUID()
        conversation.createdAt = Date()
        conversation.title = title
        conversation.systemMessage = systemMessage
        
        do {
            try context.save()
        } catch {
            print("Failed to insert conversation: \(error)")
        }
        return conversation
    }

    func deleteConversation(id: UUID) {
        let context = persistence.container.newBackgroundContext()
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let conversation = try context.fetch(request).first
            if let conversation = conversation {
                context.delete(conversation)
                try context.save()
            }
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }
    
    func updateConversation(id: UUID, title: String) {
        let context = persistence.container.newBackgroundContext()
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let conversation = try context.fetch(request).first
            conversation?.title = title
            try context.save()
        } catch {
            print("Failed to update conversation: \(error)")
        }
    }

    func fetchConversation(by id: UUID) -> Conversation {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let conversations = try context.fetch(request)
            guard let conversation = conversations.first else {
                fatalError("Conversation not found for the given id")
            }
            return conversation
        } catch {
            fatalError("Failed to fetch conversation: \(error)")
        }
    }
}


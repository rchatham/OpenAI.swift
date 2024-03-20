//
//  ConversationService.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation
import OpenAI

class ConversationService {
    let networkClient: NetworkClient
    let conversationDB: ConversationDB
    @Published var  newMessageService: MessageService?
    
    init(networkClient: NetworkClient = NetworkClient.shared, conversationDB: ConversationDB) {
        self.networkClient = networkClient
        self.conversationDB = conversationDB
    }
    
    func messageService() -> MessageService {
        return MessageService(messageDB: MessageDB(persistence: conversationDB.persistence))
    }
    
    func createConversation(title: String, systemMessage: String) -> Conversation {
        conversationDB.createConversation(title: title, systemMessage: systemMessage)
    }

    func deleteConversation(id: UUID) {
        conversationDB.deleteConversation(id: id)
    }

    func updateConversation(id: UUID, title: String) {
        conversationDB.updateConversation(id: id, title: title)
    }
    
    func fetchConversation(by id: UUID) -> Conversation? {
        return conversationDB.fetchConversation(by: id)
    }
    
    func getTitleForConversation(withSystemMessage systemMessage: String) async throws -> Conversation {
        let messages = [
            OpenAI.Message(role: .system, content: "You are a bot that will take a system message for another bot from the user and generate a short title for the conversation that the user will have with the bot that this system message is for. Make the title short, less that 100 characters, and don't add any additional response before or after the title. Do not include quotation marks."),
            OpenAI.Message(role: .user, content: systemMessage)
        ]
        let response = try await networkClient.performChatCompletionRequest(messages: messages, model: .gpt35Turbo)
        if case .string(let title) = response.choices.first?.message?.content {
            return createConversation(title: title, systemMessage: systemMessage)
        } else {
            throw ConversationError.failedToGenerateTitle
        }
    }
}

enum ConversationError: Error {
    case failedToGenerateTitle
}

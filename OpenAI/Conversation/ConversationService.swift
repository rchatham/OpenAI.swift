//
//  ConversationService.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation

class ConversationService {
    let networkClient: NetworkClient
    let conversationDB: ConversationDB
    @Published var  newMessageService: MessageService?
    
    init(networkClient: NetworkClient = NetworkClient(), conversationDB: ConversationDB) {
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
    
    func getTitleForConversation(withSystemMessage systemMessage: String, completion: @escaping (Result<OpenAIChatAPI.ChatCompletionResponse, Error>) -> Void) throws {
        let messages = [
            OpenAIChatAPI.Message(role: .system, content: "You are a bot that will take a system message for another bot from the user and generate a short title for the conversation the user will have with the bot this system message is for. Make the title short, less that 100 characters, and don't add any additional response before or after the title. Do not include quotation marks."),
            OpenAIChatAPI.Message(role: .user, content: systemMessage)
        ]
        try networkClient.sendChatCompletionRequest(messages: messages, model: .gpt35Turbo0301) { (result: Result<OpenAIChatAPI.ChatCompletionResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response): completion(.success(response))
                case .failure(let error): completion(.failure(error))
                }
            }
        }
    }
}

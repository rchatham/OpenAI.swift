//
//  MessageService.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation

class MessageService {
    let networkClient: NetworkClient
    let messageDB: MessageDB
    
    init(networkClient: NetworkClient = NetworkClient(), messageDB: MessageDB) {
        self.networkClient = networkClient
        self.messageDB = messageDB
    }
    
    func sendMessageCompletionRequest(message: String, for conversation: Conversation) throws {
        messageDB.createMessage(for: conversation, from: message)
        let messages = conversation.toNetworkMessages()
        try networkClient.sendChatCompletionRequest(messages: messages) { [conversation] result in
            switch result {
            case .success(let response):
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self, let message = response.choices.first?.message else { return }
                    strongSelf.messageDB.createMessage(for: conversation, from: message)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func updateMessage(id: UUID, role: String, content: String) {
        messageDB.updateMessage(id: id, role: role, content: content)
    }

    func deleteMessage(id: UUID) {
        messageDB.deleteMessage(id: id)
    }
}

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
    
    func sendMessageCompletionRequest(message: String, for conversation: Conversation, stream: Bool = false) throws {
        messageDB.createMessage(for: conversation, with: message)
        let messages = conversation.toNetworkMessages()

        class NewMessageInfo {
            var id: UUID
            var content = ""
            private let messageDB: MessageDB
            init(for conversation: Conversation, using messageDB: MessageDB) {
                id = messageDB.createMessage(for: conversation, with: "", asUser: false).id!
                self.messageDB = messageDB
            }
            func append(chunk: String) {
                content = content + chunk
                messageDB.updateMessage(id: id, content: content)
            }
        }
        var newMessageInfo: NewMessageInfo?

        try networkClient.sendChatCompletionRequest(messages: messages, stream: stream) { [conversation] result in
            switch result {
            case .success(let response):
                if let message = response.choices.first?.message {
                    DispatchQueue.main.async { [weak self] in
                        self?.messageDB.createMessage(for: conversation, from: message)
                    }
                }
                if let delta = response.choices.first?.delta {
                    DispatchQueue.main.async { [weak self] in
                        if delta.role == .assistant, let messageDB = self?.messageDB
                        { newMessageInfo = NewMessageInfo(for: conversation, using: messageDB)}
                        if let chunk = delta.content { newMessageInfo?.append(chunk: chunk)}
                    }
                }

            case .failure(let error): print(error.localizedDescription)
            }
        }
    }

    func deleteMessage(id: UUID) {
        messageDB.deleteMessage(id: id)
    }
}

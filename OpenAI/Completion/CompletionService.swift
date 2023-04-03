//
//  CompletionService.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/21/23.
//

import Foundation

class CompletionService {
    let networkClient: NetworkClient
    let completionDB: CompletionDB
    
    init(networkClient: NetworkClient = NetworkClient(), completionDB: CompletionDB) {
        self.networkClient = networkClient
        self.completionDB = completionDB
    }
    
    func getCompletion(for prompt: String) async throws {
        try await networkClient.getCompletion(for: prompt) { prompt, response in
            DispatchQueue.main.async { [weak self] in
                self?.completionDB.createCompletion(prompt: prompt, response: response)
            }
        }
    }

    func deleteCompletion(id: UUID) {
        completionDB.deleteCompletion(id: id)
    }

    func updateCompletion(id: UUID, prompt: String, response: String) {
        completionDB.updateCompletion(id: id, prompt: prompt, response: response)
    }
    
    func updateApiKey(_ apiKey: String) throws {
        try networkClient.updateApiKey(apiKey)
    }
}

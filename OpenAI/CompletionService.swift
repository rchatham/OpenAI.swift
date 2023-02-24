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
    
    init(networkClient: NetworkClient = NetworkClient(), completionDB: CompletionDB = CompletionDB()) {
        self.networkClient = networkClient
        self.completionDB = completionDB
    }
    
    func getCompletion(for prompt: String, completion: @escaping () -> Void) async throws {
        try await networkClient.getCompletion(for: prompt) { prompt, response in
            DispatchQueue.main.async { [weak self] in
                self?.completionDB.createCompletion(prompt: prompt, response: response)
                completion()
            }
        }
    }

//    func fetchCompletions(completion: @escaping (_ completions: [Completion]) -> ()) {
//        completionDB.fetchCompletions { completions in
//            completion(completions)
//        }
//    }

    func deleteCompletion(id: UUID) {
        completionDB.deleteCompletion(id: id)
    }

    func updateCompletion(id: UUID, prompt: String, response: String) {
        completionDB.updateCompletion(id: id, prompt: prompt, response: response)
    }
    
    func updateApiKey(_ apiKey: String) {
        networkClient.updateApiKey(apiKey)
    }
}

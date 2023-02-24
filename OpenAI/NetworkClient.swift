//
//  NetworkClient.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import Foundation
import OpenAISwift

class NetworkClient {
    private let keychainService = KeychainService()
    private var openAI: OpenAISwift?
    private let userDefaults = UserDefaults.standard
    
    init() {
        if let apiKey = keychainService.getApiKey() {
            openAI = OpenAISwift(authToken: apiKey)
        }
    }

    func getCompletion(for prompt: String, completionHandler: @escaping (_ prompt: String, _ response: String) -> ()) async throws {
        guard let openAI = openAI else { throw NetworkError.missingApiKey }
        await openAI.sendCompletion(with: prompt, model: userDefaults.model, maxTokens: userDefaults.maxTokens, temperature: userDefaults.temperature) { (result: Result<OpenAI, OpenAIError>) in
            switch result {
            case .success(let success):
                completionHandler(prompt, success.choices.first?.text ?? "NOPE")
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }
    }
    
    func updateApiKey(_ apiKey: String) {
        keychainService.saveApiKey(apiKey: apiKey)
        openAI = OpenAISwift(authToken: apiKey)
    }
}

extension NetworkClient {
    enum NetworkError: Error {
        case missingApiKey
    }
}

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
    private var openAIChat: OpenAIChatAPI?
    private let userDefaults = UserDefaults.standard
    
    init() {
        if let apiKey = keychainService.getApiKey() {
            openAI = OpenAISwift(authToken: apiKey, promoptsHistoryEnable: true)
            openAIChat = OpenAIChatAPI(apiKey: apiKey)
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
    
    func sendChatCompletionRequest(messages: [ChatCompletionRequest.Message], model: Model = .gpt35Turbo0301, completion: @escaping (Result<ChatCompletionResponse, APIError>) -> Void) throws {
        guard let openAIChat = openAIChat else { throw NetworkError.missingApiKey }
        openAIChat.sendChatCompletionRequest(model: model, messages: messages) { (result: Result<ChatCompletionResponse, APIError>) in
            switch result {
            case .success(let response):
                print(response.choices.first?.message.content ?? "NOPE")
            case .failure(let error):
                print(error.localizedDescription)
            }
            completion(result)
        }
    }
    
    func updateApiKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw NetworkError.emptyApiKey
        }
        keychainService.saveApiKey(apiKey: apiKey)
        openAI = OpenAISwift(authToken: apiKey, promoptsHistoryEnable: true)
        openAIChat = OpenAIChatAPI(apiKey: apiKey)
    }
}

extension NetworkClient {
    enum NetworkError: Error {
        case missingApiKey
        case emptyApiKey
    }
}

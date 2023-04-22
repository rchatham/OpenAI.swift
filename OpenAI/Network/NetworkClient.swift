//
//  NetworkClient.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import Foundation

class NetworkClient: NSObject, URLSessionWebSocketDelegate {
    static let shared = NetworkClient()

    private let keychainService = KeychainService()
    private var openAIChat: OpenAIChatAPI?
    private let userDefaults = UserDefaults.standard
    private var streamCompletion: ((Result<String, APIError>) -> Void)?

    override init() {
        super.init()
        if let apiKey = keychainService.getApiKey() {
            openAIChat = OpenAIChatAPI(apiKey: apiKey)
        }
    }

    func sendChatCompletionRequest(messages: [ChatCompletionRequest.Message], model: Model = .gpt4, stream: Bool = false, completion: @escaping (Result<ChatCompletionResponse, Error>) -> Void) throws {
        guard let openAIChat = openAIChat else { throw NetworkError.missingApiKey }
        openAIChat.sendChatCompletionRequest(model: model, messages: messages, stream: stream) { (result: Result<ChatCompletionResponse, Error>) in
            switch result {
            case .success(let response):
                print(response.choices.first?.message?.content ?? response.choices.first?.delta?.content ?? "NOPE")
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
        openAIChat = OpenAIChatAPI(apiKey: apiKey)
    }
}

extension NetworkClient {
    enum NetworkError: Error {
        case missingApiKey
        case emptyApiKey
    }
}
